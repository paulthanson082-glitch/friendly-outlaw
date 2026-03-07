"""
Google Analytics 4 Integration
Fetches traffic and engagement data from GA4.

Setup: See data_sources/README.md for credential configuration.
"""

import os
from datetime import datetime, timedelta
from typing import Optional

try:
    from google.analytics.data_v1beta import BetaAnalyticsDataClient
    from google.analytics.data_v1beta.types import (
        DateRange, Dimension, Metric, RunReportRequest
    )
    from google.oauth2 import service_account
    GA4_AVAILABLE = True
except ImportError:
    GA4_AVAILABLE = False


class GoogleAnalytics:
    """Interface for Google Analytics 4 data."""

    def __init__(self):
        self.property_id = os.getenv("GA4_PROPERTY_ID")
        self.credentials_path = os.getenv(
            "GA4_CREDENTIALS_PATH",
            "data_sources/config/ga4_credentials.json"
        )
        self.client = None
        self._initialized = False

    def _init_client(self):
        """Initialize GA4 client lazily."""
        if self._initialized:
            return

        if not GA4_AVAILABLE:
            raise ImportError(
                "google-analytics-data package not installed. "
                "Run: pip install google-analytics-data"
            )

        if not self.property_id:
            raise ValueError("GA4_PROPERTY_ID environment variable not set")

        if not os.path.exists(self.credentials_path):
            raise FileNotFoundError(
                f"GA4 credentials not found at {self.credentials_path}. "
                "See data_sources/README.md for setup instructions."
            )

        credentials = service_account.Credentials.from_service_account_file(
            self.credentials_path,
            scopes=["https://www.googleapis.com/auth/analytics.readonly"]
        )
        self.client = BetaAnalyticsDataClient(credentials=credentials)
        self._initialized = True

    def get_page_performance(self, days: int = 30, limit: int = 50) -> list:
        """
        Get top pages by sessions for the specified period.

        Returns:
            List of dicts with page data
        """
        self._init_client()

        end_date = datetime.now().strftime("%Y-%m-%d")
        start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

        request = RunReportRequest(
            property=f"properties/{self.property_id}",
            dimensions=[Dimension(name="pagePath"), Dimension(name="pageTitle")],
            metrics=[
                Metric(name="sessions"),
                Metric(name="engagedSessions"),
                Metric(name="averageSessionDuration"),
                Metric(name="bounceRate"),
                Metric(name="conversions"),
            ],
            date_ranges=[DateRange(start_date=start_date, end_date=end_date)],
            limit=limit,
            order_bys=[{"metric": {"metric_name": "sessions"}, "desc": True}],
        )

        response = self.client.run_report(request)

        results = []
        for row in response.rows:
            results.append({
                "page_path": row.dimension_values[0].value,
                "page_title": row.dimension_values[1].value,
                "sessions": int(row.metric_values[0].value),
                "engaged_sessions": int(row.metric_values[1].value),
                "avg_duration_seconds": float(row.metric_values[2].value),
                "bounce_rate": float(row.metric_values[3].value),
                "conversions": int(row.metric_values[4].value),
                "period_days": days,
            })

        return results

    def get_traffic_trends(self, days: int = 90) -> list:
        """Get daily traffic trends for trend analysis."""
        self._init_client()

        end_date = datetime.now().strftime("%Y-%m-%d")
        start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

        request = RunReportRequest(
            property=f"properties/{self.property_id}",
            dimensions=[Dimension(name="date")],
            metrics=[
                Metric(name="sessions"),
                Metric(name="activeUsers"),
            ],
            date_ranges=[DateRange(start_date=start_date, end_date=end_date)],
            order_bys=[{"dimension": {"dimension_name": "date"}}],
        )

        response = self.client.run_report(request)

        return [
            {
                "date": row.dimension_values[0].value,
                "sessions": int(row.metric_values[0].value),
                "users": int(row.metric_values[1].value),
            }
            for row in response.rows
        ]

    def is_configured(self) -> bool:
        """Check if GA4 credentials are configured."""
        return bool(self.property_id) and os.path.exists(self.credentials_path)


class GoogleAnalyticsMock:
    """Mock GA4 client for development/testing without credentials."""

    def get_page_performance(self, days: int = 30, limit: int = 50) -> list:
        return [
            {
                "page_path": "/blog/example-article",
                "page_title": "Example Article",
                "sessions": 1250,
                "engaged_sessions": 890,
                "avg_duration_seconds": 185.5,
                "bounce_rate": 0.42,
                "conversions": 23,
                "period_days": days,
                "_mock": True,
            }
        ]

    def is_configured(self) -> bool:
        return False


def get_analytics_client():
    """Get the appropriate analytics client based on configuration."""
    client = GoogleAnalytics()
    if client.is_configured():
        return client
    else:
        print("GA4 not configured — using mock data. See data_sources/README.md to set up.")
        return GoogleAnalyticsMock()
