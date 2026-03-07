"""
Google Search Console Integration
Fetches ranking and CTR data from Search Console.

Setup: See data_sources/README.md for credential configuration.
"""

import os
from datetime import datetime, timedelta
from typing import Optional

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    GSC_AVAILABLE = True
except ImportError:
    GSC_AVAILABLE = False


class GoogleSearchConsole:
    """Interface for Google Search Console data."""

    SCOPES = ["https://www.googleapis.com/auth/webmasters.readonly"]

    def __init__(self):
        self.site_url = os.getenv("GSC_SITE_URL")
        self.credentials_path = os.getenv(
            "GA4_CREDENTIALS_PATH",  # Same credentials file as GA4
            "data_sources/config/ga4_credentials.json"
        )
        self.service = None
        self._initialized = False

    def _init_service(self):
        """Initialize GSC service lazily."""
        if self._initialized:
            return

        if not GSC_AVAILABLE:
            raise ImportError(
                "google-api-python-client not installed. "
                "Run: pip install google-api-python-client"
            )

        if not self.site_url:
            raise ValueError("GSC_SITE_URL environment variable not set")

        if not os.path.exists(self.credentials_path):
            raise FileNotFoundError(
                f"Credentials not found at {self.credentials_path}. "
                "See data_sources/README.md for setup instructions."
            )

        credentials = service_account.Credentials.from_service_account_file(
            self.credentials_path,
            scopes=self.SCOPES
        )
        self.service = build("searchconsole", "v1", credentials=credentials)
        self._initialized = True

    def get_page_rankings(self, days: int = 30, row_limit: int = 1000) -> list:
        """
        Get page-level performance data from Search Console.

        Returns:
            List of dicts with page ranking data
        """
        self._init_service()

        end_date = datetime.now().strftime("%Y-%m-%d")
        start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

        request = {
            "startDate": start_date,
            "endDate": end_date,
            "dimensions": ["page", "query"],
            "rowLimit": row_limit,
            "orderBy": [{"fieldName": "impressions", "sortOrder": "DESCENDING"}],
        }

        response = self.service.searchanalytics().query(
            siteUrl=self.site_url,
            body=request
        ).execute()

        results = []
        for row in response.get("rows", []):
            keys = row.get("keys", [])
            results.append({
                "page": keys[0] if len(keys) > 0 else "",
                "query": keys[1] if len(keys) > 1 else "",
                "clicks": row.get("clicks", 0),
                "impressions": row.get("impressions", 0),
                "ctr": round(row.get("ctr", 0) * 100, 2),
                "position": round(row.get("position", 0), 1),
                "period_days": days,
            })

        return results

    def get_quick_wins(self, days: int = 30) -> list:
        """
        Identify pages ranking positions 11-20 (near page 1).

        Returns pages that could break into page 1 with optimization.
        """
        all_data = self.get_page_rankings(days=days)

        # Group by page, get average position
        page_data = {}
        for row in all_data:
            page = row["page"]
            if page not in page_data:
                page_data[page] = {
                    "page": page,
                    "queries": [],
                    "total_impressions": 0,
                    "total_clicks": 0,
                }
            page_data[page]["queries"].append(row)
            page_data[page]["total_impressions"] += row["impressions"]
            page_data[page]["total_clicks"] += row["clicks"]

        # Find quick wins: position 11-20 with decent impressions
        quick_wins = []
        for page, data in page_data.items():
            for query_row in data["queries"]:
                if 11 <= query_row["position"] <= 20 and query_row["impressions"] >= 50:
                    quick_wins.append({
                        **query_row,
                        "opportunity": "Near page 1 — optimize for this keyword",
                    })

        return sorted(quick_wins, key=lambda x: x["impressions"], reverse=True)

    def get_low_ctr_opportunities(self, days: int = 30, min_impressions: int = 100) -> list:
        """
        Find pages with high impressions but low CTR.

        These pages rank well but need better meta titles/descriptions.
        """
        all_data = self.get_page_rankings(days=days)

        opportunities = []
        for row in all_data:
            if row["impressions"] >= min_impressions and row["ctr"] < 3.0 and row["position"] <= 10:
                opportunities.append({
                    **row,
                    "opportunity": "Good rank but low CTR — improve meta title/description",
                })

        return sorted(opportunities, key=lambda x: x["impressions"], reverse=True)

    def is_configured(self) -> bool:
        """Check if GSC credentials are configured."""
        return bool(self.site_url) and os.path.exists(self.credentials_path)


class GoogleSearchConsoleMock:
    """Mock GSC client for development/testing without credentials."""

    def get_page_rankings(self, days: int = 30, row_limit: int = 1000) -> list:
        return [
            {
                "page": "https://yoursite.com/blog/example",
                "query": "example keyword",
                "clicks": 45,
                "impressions": 1200,
                "ctr": 3.75,
                "position": 12.3,
                "period_days": days,
                "_mock": True,
            }
        ]

    def get_quick_wins(self, days: int = 30) -> list:
        return []

    def get_low_ctr_opportunities(self, days: int = 30, min_impressions: int = 100) -> list:
        return []

    def is_configured(self) -> bool:
        return False


def get_gsc_client():
    """Get the appropriate GSC client based on configuration."""
    client = GoogleSearchConsole()
    if client.is_configured():
        return client
    else:
        print("GSC not configured — using mock data. See data_sources/README.md to set up.")
        return GoogleSearchConsoleMock()
