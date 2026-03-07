"""
DataForSEO Integration
Fetches keyword data, SERP analysis, and competitor rankings.

Setup: Add DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD to .env
"""

import os
import json
import base64
from typing import Optional

try:
    import requests
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False


class DataForSEO:
    """Interface for DataForSEO API."""

    BASE_URL = "https://api.dataforseo.com/v3"

    def __init__(self):
        self.login = os.getenv("DATAFORSEO_LOGIN")
        self.password = os.getenv("DATAFORSEO_PASSWORD")

    def _get_headers(self) -> dict:
        """Get authentication headers."""
        if not self.login or not self.password:
            raise ValueError(
                "DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD environment variables not set. "
                "See data_sources/README.md for setup instructions."
            )
        credentials = base64.b64encode(f"{self.login}:{self.password}".encode()).decode()
        return {
            "Authorization": f"Basic {credentials}",
            "Content-Type": "application/json",
        }

    def get_keyword_data(self, keywords: list, location_code: int = 2840) -> list:
        """
        Get keyword search volume and difficulty data.

        Args:
            keywords: List of keywords to look up
            location_code: Country code (2840 = United States)

        Returns:
            List of keyword data dicts
        """
        if not REQUESTS_AVAILABLE:
            raise ImportError("requests package not installed. Run: pip install requests")

        payload = [
            {
                "keywords": keywords,
                "location_code": location_code,
                "language_code": "en",
            }
        ]

        response = requests.post(
            f"{self.BASE_URL}/keywords_data/google_ads/search_volume/live",
            headers=self._get_headers(),
            json=payload,
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()

        results = []
        for task in data.get("tasks", []):
            for item in task.get("result", []) or []:
                results.append({
                    "keyword": item.get("keyword"),
                    "search_volume": item.get("search_volume", 0),
                    "competition": item.get("competition", 0),
                    "cpc": item.get("cpc", 0),
                    "monthly_searches": item.get("monthly_searches", []),
                })

        return results

    def get_serp_competitors(self, keyword: str, location_code: int = 2840, limit: int = 10) -> list:
        """
        Get SERP results for a keyword to analyze top-ranking competitors.

        Args:
            keyword: Target keyword
            location_code: Country code
            limit: Number of results to return

        Returns:
            List of SERP result dicts
        """
        if not REQUESTS_AVAILABLE:
            raise ImportError("requests package not installed. Run: pip install requests")

        payload = [
            {
                "keyword": keyword,
                "location_code": location_code,
                "language_code": "en",
                "device": "desktop",
                "depth": limit,
            }
        ]

        response = requests.post(
            f"{self.BASE_URL}/serp/google/organic/live/regular",
            headers=self._get_headers(),
            json=payload,
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()

        results = []
        for task in data.get("tasks", []):
            for result_set in task.get("result", []) or []:
                for item in result_set.get("items", []) or []:
                    if item.get("type") == "organic":
                        results.append({
                            "rank": item.get("rank_absolute"),
                            "url": item.get("url"),
                            "title": item.get("title"),
                            "description": item.get("description"),
                            "domain": item.get("domain"),
                        })

        return results[:limit]

    def is_configured(self) -> bool:
        """Check if DataForSEO credentials are configured."""
        return bool(self.login) and bool(self.password)


class DataForSEOMock:
    """Mock DataForSEO client for development/testing without credentials."""

    def get_keyword_data(self, keywords: list, location_code: int = 2840) -> list:
        return [
            {
                "keyword": kw,
                "search_volume": 1000,
                "competition": 0.65,
                "cpc": 2.50,
                "monthly_searches": [],
                "_mock": True,
            }
            for kw in keywords
        ]

    def get_serp_competitors(self, keyword: str, location_code: int = 2840, limit: int = 10) -> list:
        return [
            {
                "rank": i + 1,
                "url": f"https://competitor{i+1}.com/article",
                "title": f"Example result {i+1} for '{keyword}'",
                "description": "This is a mock SERP result.",
                "domain": f"competitor{i+1}.com",
                "_mock": True,
            }
            for i in range(min(limit, 5))
        ]

    def is_configured(self) -> bool:
        return False


def get_dataforseo_client():
    """Get the appropriate DataForSEO client based on configuration."""
    client = DataForSEO()
    if client.is_configured():
        return client
    else:
        print("DataForSEO not configured — using mock data. See data_sources/README.md to set up.")
        return DataForSEOMock()
