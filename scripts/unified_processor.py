#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import requests
import time
import argparse
import os
import logging
import re
from typing import Dict, Any, List
from multiprocessing import Pool
from tqdm import tqdm
from prettytable import PrettyTable

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('unified_processor.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


# Global processor instance to avoid repeated creation
_global_processor = None


def init_worker(server_ip, server_port):
    """Initialize worker process"""
    global _global_processor
    _global_processor = UnifiedProcessor(server_ip, server_port)


def process_single_data_worker(data, index, debug, print_code=False):
    """Single task worker function to process one data item"""
    global _global_processor

    result = _global_processor.process_data(data, debug, print_code)
    result["index"] = index
    result["original_data"] = data

    time.sleep(0.2)  # Appropriate delay to avoid API overload
    return result


class UnifiedProcessor:
    def __init__(self, server_ip: str = "localhost", server_port: int = 8080):
        self.server_ip = server_ip
        self.server_port = server_port
        self.submit_url = f"http://{server_ip}:{server_port}/submit"
        self.headers = {
            "Content-Type": "application/json"
        }


    def read_jsonl_file(self, file_path: str, line_number: int = None, target_language: str = None) -> List[Dict[str, Any]]:
        """Read JSONL file and return data list"""
        data_list = []
        total_count = 0
        filtered_count = 0

        with open(file_path, 'r', encoding='utf-8') as file:
            for line_num, line in enumerate(file, 1):
                line = line.strip()
                if line:
                    try:
                        data = json.loads(line)

                        total_count += 1

                        # Language filtering
                        if target_language:
                            data_language = data.get("language", "").lower()
                            if data_language != target_language.lower():
                                continue
                            filtered_count += 1
                        else:
                            filtered_count += 1

                        # Add absolute and relative line number information
                        data['_absolute_line_number'] = line_num
                        data['_relative_line_number'] = filtered_count
                        data_list.append(data)
                    except json.JSONDecodeError as e:
                        logger.error(f"JSON parsing error at line {line_num}: {e}")
                        continue

            if target_language:
                logger.info(f"Language filter: {target_language} - Total {total_count} items, matched {filtered_count} items, finally read {len(data_list)} items")
            else:
                logger.info(f"Successfully read {len(data_list)} items")
            return data_list


    def extract_fields(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Extract required fields"""
        return {
            "language": data.get("language", "").lower(),
            "full_test_func": data.get("full_test_func", ""),
            "main_test_func": data.get("extracted_code", "")
        }

    def call_submit_api(self, data: Dict[str, Any], test_type: str = "full", debug: bool = False, print_code: bool = False) -> Dict[str, Any]:
        """Call submit API"""
        try:
            language = data["language"]

            # Select test code based on test type
            if test_type == "full":
                test_code = data["full_test_func"]
            else:
                raise ValueError(f"Unsupported test type: {test_type}")

            payload = {
                "src_uid": f"bench_test_{test_type}_{int(time.time())}",
                "func_code": data["main_test_func"],  # code solution
                "main_code": test_code,  # test function
                "lang": language,
                "show_log": "true",
                "request_extensions": {"timeout": 30, "debug": str(debug).lower()}
            }

            response = requests.post(self.submit_url, headers=self.headers, json=payload, timeout=60)

            if response.status_code == 200:
                result = response.json()
                return {
                    "success": True,
                    "response": result,
                    "status_code": response.status_code
                }
            else:
                logger.error(f"API call failed, status code: {response.status_code}, response: {response.text}")
                return {
                    "success": False,
                    "error": f"HTTP {response.status_code}: {response.text}",
                    "status_code": response.status_code
                }
        except Exception as e:
            logger.error(f"Error occurred while processing data: {e}")
            return {
                "success": False,
                "error": str(e),
                "status_code": None
            }

    def process_data(self, data: Dict[str, Any], debug: bool = False, print_code: bool = False) -> Dict[str, Any]:
        """Process single data item, call submit API"""
        extracted_data = self.extract_fields(data)

        # Check if necessary fields exist
        if not all(extracted_data.values()):
            logger.warning("Data missing required fields, skipping processing")
            return {
                "success": False,
                "error": "Missing required fields",
                "full_test_result": None,
                "language": extracted_data["language"]
            }

        # Call full_test_func
        full_test_result = self.call_submit_api(extracted_data, "full", debug, print_code)
        time.sleep(0.5)

        # Determine overall success (both API calls succeed and code execution passes)
        full_api_success = full_test_result.get("success", False)
        full_exec_passed = (full_api_success and
                           full_test_result.get("response", {}).get("exec_outcome") == "PASSED")
        overall_success = full_exec_passed

        return {
            "success": overall_success,
            "full_test_result": full_test_result,
            "language": extracted_data["language"],
            "full_test_detail": full_test_result.get("response", {})
        }

    def process_file(self, file_path: str, max_items: int = None, line_number: int = None,
                     debug: bool = False, concurrency: int = 5, target_language: str = None,
                     solution_key: str = 'output') -> List[Dict[str, Any]]:
        """Process entire JSONL file"""
        logger.info(f"Start processing file: {file_path}")
        if target_language:
            logger.info(f"Language filter: only processing {target_language} language data")

        # Read data
        data_list = self.read_jsonl_file(file_path, line_number, target_language)

        def _extract_code_blocks(output: str, language: str, solution: str) -> str:
            """Extract code blocks from output field, format: ```{language}\n{code}```"""
            if not output: return ""
            if "</think>" in output: output = output.split("</think>")[-1]

            pattern = r'```(?:\S*)\s*(.*?)```'
            matches = re.findall(pattern, output, re.DOTALL)
            if matches:
                extract_code = matches[0].strip()  # only return the code
            else:
                return ''

            if language == "elixir":
                code_list = extract_code.split("\n")
                solution_list = solution.strip().split("\n")
                assert solution_list[0].startswith("defmodule") and solution_list[-1].startswith("end")
                if code_list[0].startswith("defmodule") and code_list[-1].startswith("end"):
                    code_list = code_list[1:-1]
                    code_list = [solution_list[0]] + code_list + [solution_list[-1]]
                else:
                    code_list = ["  " + line for line in code_list]
                    code_list = [solution_list[0]] + code_list + [solution_list[-1]]
                extract_code = "\n".join(code_list)

            return extract_code


        for data in data_list:
            extract_code = _extract_code_blocks(data[solution_key], data["language"], data["signature"])
            data["extracted_code"] = extract_code if extract_code else "error! no code extracted"

        # Use multiprocess mode
        logger.info(f"Using multiprocess mode, concurrency: {concurrency}")
        return self._process_file_multiprocess(data_list, debug, concurrency)

    def _process_file_serial(self, data_list: List[Dict[str, Any]], line_number: int = None,
                           debug: bool = False) -> List[Dict[str, Any]]:
        """Process file serially"""
        results = []

        # Check if single line mode (for printing code)
        is_single_line_mode = line_number is not None

        # Use tqdm to show progress
        desc = f"Processing line {line_number} data" if line_number else "Serial processing"
        with tqdm(total=len(data_list), desc=desc, unit="items") as pbar:
            for i, data in enumerate(data_list, 1):
                result = self.process_data(data, debug, print_code=is_single_line_mode)
                result["index"] = i
                result["original_data"] = data
                results.append(result)

                # Update progress bar
                pbar.update(1)
                pbar.set_postfix({
                    "Success": sum(1 for r in results if r.get("success", False)),
                    "Failed": sum(1 for r in results if not r.get("success", False))
                })

                # Wait slightly between each processing to avoid too frequent requests
                if i < len(data_list):
                    time.sleep(0.1)

        logger.info(f"Serial processing completed, processed {len(results)} items")
        return results

    def _process_file_multiprocess(self, data_list: List[Dict[str, Any]], debug: bool = False,
                                 concurrency: int = 5) -> List[Dict[str, Any]]:
        """Process file with multiprocessing"""
        total_items = len(data_list)

        logger.info(f"Starting {concurrency} processes to handle {total_items} items")

        results = []
        try:
            # Use process pool, each task processes one data item
            with Pool(processes=concurrency, initializer=init_worker, initargs=(self.server_ip, self.server_port)) as pool:
                # Use tqdm to show progress
                with tqdm(total=total_items, desc=f"Multiprocess ({concurrency} processes)", unit="items") as pbar:
                    # Submit all tasks
                    futures = []
                    for i, data in enumerate(data_list, 1):
                        future = pool.apply_async(process_single_data_worker, (data, i, debug, False))
                        futures.append(future)

                    # Collect results
                    for future in futures:
                        try:
                            result = future.get(timeout=300)  # 5 minutes timeout
                            results.append(result)
                            pbar.update(1)

                            # Update progress bar statistics
                            pbar.set_postfix({
                                "Success": sum(1 for r in results if r.get("success", False)),
                                "Failed": sum(1 for r in results if not r.get("success", False))
                            })
                        except Exception as e:
                            logger.error(f"Task failed: {e}")
                            # Create failed result
                            failed_result = {
                                "index": len(results) + 1,
                                "success": False,
                                "error": str(e),
                                "original_data": {}
                            }
                            results.append(failed_result)
                            pbar.update(1)

        except Exception as e:
            logger.error(f"Error occurred during multiprocess processing: {e}")
            # If multiprocessing fails, fallback to serial processing
            logger.info("Falling back to serial processing mode")
            return self._process_file_serial(data_list, debug=debug)

        # Sort results by index
        results.sort(key=lambda x: x.get("index", 0))

        logger.info(f"Multiprocess processing completed, processed {len(results)} items")
        return results

    def save_results(self, results: List[Dict[str, Any]], output_file: str):
        """Save processing results to file"""
        with open(output_file, 'w', encoding='utf-8') as f:
            for result in results:
                # Simplify output format, keep only necessary information
                simplified_result = {
                    "index": result.get("index", 0),
                    "language": result.get("language", ""),
                    "success": result.get("success", False),
                    "full_test_result": result.get("full_test_result", {}),
                    "original_data": result.get("original_data", {})
                }
                f.write(json.dumps(simplified_result, ensure_ascii=False) + '\n')
        logger.info(f"Results saved to: {output_file}")

    def print_detailed_statistics(self, results: List[Dict[str, Any]]):
        """Print detailed statistics report table"""
        if not results:
            print("\nNo data processed")
            return

        # Group statistics by language
        language_stats = {}
        failed_items = []

        for result in results:
            try:
                language = result.get("language", "unknown")
                success = result.get("success", False)
                index = result.get("index", 0)

                # Initialize language statistics
                if language not in language_stats:
                    language_stats[language] = {
                        "total": 0,
                        "success": 0,
                        "failed": 0,
                        "full_passed": 0,
                        "failed_indices": []
                    }

                # Update statistics
                stats = language_stats[language]
                stats["total"] += 1

                if success:
                    stats["success"] += 1
                else:
                    stats["failed"] += 1
                    # Get absolute and relative line numbers
                    absolute_line = result.get("original_data", {}).get("_absolute_line_number", index)
                    relative_line = result.get("original_data", {}).get("_relative_line_number", index)

                    stats["failed_indices"].append({
                        "absolute_line": absolute_line,
                        "relative_line": relative_line
                    })
                    failed_items.append({
                        "index": index,
                        "absolute_line": absolute_line,
                        "relative_line": relative_line,
                        "language": language,
                        "full_outcome": result.get("full_test_result", {}).get("response", {}).get("exec_outcome", "unknown"),
                        "full_error": result.get("full_test_result", {}).get("error", "")
                    })

                # Detailed test result statistics
                full_outcome = result.get("full_test_result", {}).get("response", {}).get("exec_outcome", "")

                if full_outcome == "PASSED":
                    stats["full_passed"] += 1
            except Exception as e:
                logger.error(f"Error occurred while calculating test statistics: {e} data:\n {result}")
                continue

        # Print overall statistics
        total_items = len(results)
        total_success = sum(1 for r in results if r.get("success", False))
        total_failed = total_items - total_success

        print("\n" + "="*80)
        print("Execution Results Statistics Report")
        print("="*80)

        print(f"\nOverall Statistics:")
        print(f"   Total Processed: {total_items} items")
        print(f"   Success:        {total_success} items ({total_success/total_items*100:.1f}%)")
        print(f"   Failed:         {total_failed} items ({total_failed/total_items*100:.1f}%)")

        # Use PrettyTable to print detailed statistics by language
        print(f"\nDetailed Statistics by Language:")
        language_table = PrettyTable()
        language_table.field_names = ["Language", "Total", "Success", "Failed", "Success Rate", "Full Passed"]
        language_table.align = "l"
        language_table.align["Total"] = "r"
        language_table.align["Success"] = "r"
        language_table.align["Failed"] = "r"
        language_table.align["Success Rate"] = "r"
        language_table.align["Full Passed"] = "r"

        # Add data sorted by language name
        for language in sorted(language_stats.keys()):
            stats = language_stats[language]
            success_rate = stats["success"] / stats["total"] * 100 if stats["total"] > 0 else 0

            language_table.add_row([
                language,
                stats["total"],
                stats["success"],
                stats["failed"],
                f"{success_rate:.1f}%",
                stats["full_passed"]
            ])

        print(language_table)


def main():
    parser = argparse.ArgumentParser(description='Unified JSONL file processor (supports all languages)')
    parser.add_argument('-i', '--input_file', help='Input JSONL file path')
    parser.add_argument('-o', '--output', help='Output file path')
    parser.add_argument('-m', '--max-items', type=int, help='Maximum number of items to process')
    parser.add_argument('-l', '--line', type=int, help='Specify which line to process (starting from 1)')
    parser.add_argument('--server_ip', help='Server IP address', default='localhost')
    parser.add_argument('--server_port', type=int, help='Server port', default=8080)
    parser.add_argument('-d', '--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('-c', '--concurrency', type=int, default=30, help='Number of concurrent processes (default 30)')
    parser.add_argument('--lang', help='Specify programming language to process, only process data of that language')
    parser.add_argument('--solution_key', default='output', help='Specify the key name where the solution is located')

    args = parser.parse_args()

    if args.concurrency > 20:
        logger.warning("High concurrency may put pressure on the server, recommended not to exceed 20")

    # Create processor
    processor = UnifiedProcessor(args.server_ip, args.server_port)

    # Process file
    results = processor.process_file(args.input_file, args.max_items, args.line, args.debug, args.concurrency, args.lang, args.solution_key)

    # Determine output filename
    if args.output:
        output_file = args.output
    else:
        # Extract language information from input filename, generate output filename with language prefix
        input_basename = os.path.basename(args.input_file)
        base_name = input_basename.replace('.jsonl', '')  # e.g.: typescript.jsonl -> typescript

        # If language filter is specified, reflect it in the filename
        if args.lang:
            output_file = f"{base_name}_{args.lang}_results.jsonl"
        else:
            output_file = f"{base_name}_results.jsonl"

    # Save results
    if results:
        processor.save_results(results, output_file)

        # Generate detailed statistics report
        processor.print_detailed_statistics(results)
    else:
        logger.warning("No data processed")


if __name__ == "__main__":
    main()
