# =============================================
# streamlit_app/app.py
# NHS Prescribing Data Dashboard
# =============================================

import os
import streamlit as st
import pandas as pd
import plotly.express as px
from pyathena import connect
from pyathena.pandas.cursor import PandasCursor

st.set_page_config(
    page_title="NHS Prescribing Dashboard",
    page_icon="🏥",
    layout="wide"
)

# ---------------------------
# AWS credentials
# Works both locally and on Streamlit Cloud
# ---------------------------
def setup_aws_credentials():
    try:
        # Streamlit Cloud: read from secrets
        aws_secrets = st.secrets["aws"]
        os.environ["AWS_ACCESS_KEY_ID"]     = aws_secrets["AWS_ACCESS_KEY_ID"]
        os.environ["AWS_SECRET_ACCESS_KEY"] = aws_secrets["AWS_SECRET_ACCESS_KEY"]
        os.environ["AWS_DEFAULT_REGION"]    = aws_secrets["AWS_DEFAULT_REGION"]
    except Exception:
        # Local: use AWS profile (already set via export AWS_PROFILE=terraform)
        pass

setup_aws_credentials()

# ---------------------------
# Athena connection
# ---------------------------
@st.cache_resource
def get_connection():
    return connect(
        s3_staging_dir="s3://ukb-dev-euw2-s3-nhs-athena/query-results/",
        region_name="eu-west-2",
        work_group="ukb-dev-euw2-athena-nhs-workgroup",
        cursor_class=PandasCursor
    )

@st.cache_data(ttl=3600)
def run_query(query: str) -> pd.DataFrame:
    conn   = get_connection()
    cursor = conn.cursor()
    return cursor.execute(query).as_pandas()

# ---------------------------
# Header
# ---------------------------
st.title("🏥 NHS Prescribing Data Dashboard")
st.markdown("Monthly prescribing data for England — Source: NHS BSA Open Data Portal")
st.divider()

# ---------------------------
# Sidebar filters
# ---------------------------
st.sidebar.header("Filters")

selected_year = st.sidebar.selectbox(
    "Select Year",
    options=[2025, 2024, 2023],
    index=0
)

selected_month = st.sidebar.selectbox(
    "Select Month",
    options=list(range(1, 13)),
    format_func=lambda x: [
        "January", "February", "March", "April",
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    ][x-1],
    index=5
)

# ---------------------------
# Metric cards
# ---------------------------
st.subheader("Summary")

col1, col2, col3 = st.columns(3)

total_query = f"""
    SELECT
        SUM(total_items) AS total_items,
        SUM(total_cost)  AS total_cost,
        COUNT(DISTINCT practice_code) AS total_practices
    FROM ukb_dev_nhs_prescribing_db.practice_summary
    WHERE cast(year as varchar)  = '{selected_year}'
    AND   cast(month as varchar) = '{selected_month}'
"""

try:
    total_df = run_query(total_query)
    col1.metric(
        "Total Items Prescribed",
        f"{int(total_df['total_items'].iloc[0]):,}"
    )
    col2.metric(
        "Total Cost (£)",
        f"£{float(total_df['total_cost'].iloc[0]):,.2f}"
    )
    col3.metric(
        "GP Practices",
        f"{int(total_df['total_practices'].iloc[0]):,}"
    )
except Exception as e:
    st.error(f"Error loading summary: {e}")

st.divider()

# ---------------------------
# Chart 1 & 2
# ---------------------------
col_left, col_right = st.columns(2)

with col_left:
    st.subheader("Top 10 Drugs by Cost")
    drug_query = f"""
        SELECT
            bnf_description,
            SUM(total_cost)  AS total_cost,
            SUM(total_items) AS total_items
        FROM ukb_dev_nhs_prescribing_db.drug_summary
        WHERE cast(year as varchar)  = '{selected_year}'
        AND   cast(month as varchar) = '{selected_month}'
        GROUP BY bnf_description
        ORDER BY total_cost DESC
        LIMIT 10
    """
    try:
        drug_df = run_query(drug_query)
        fig = px.bar(
            drug_df,
            x="total_cost",
            y="bnf_description",
            orientation="h",
            labels={"total_cost": "Total Cost (£)", "bnf_description": "Drug"},
            color="total_cost",
            color_continuous_scale="Blues"
        )
        fig.update_layout(
            yaxis={"categoryorder": "total ascending"},
            showlegend=False,
            coloraxis_showscale=False
        )
        st.plotly_chart(fig, use_container_width=True)
    except Exception as e:
        st.error(f"Error loading drug data: {e}")

with col_right:
    st.subheader("Cost by Region")
    regional_query = f"""
        SELECT
            regional_office_name,
            SUM(total_cost)  AS total_cost,
            SUM(total_items) AS total_items
        FROM ukb_dev_nhs_prescribing_db.regional_trend
        WHERE cast(year as varchar)  = '{selected_year}'
        AND   cast(month as varchar) = '{selected_month}'
        GROUP BY regional_office_name
        ORDER BY total_cost DESC
    """
    try:
        regional_df = run_query(regional_query)
        fig2 = px.pie(
            regional_df,
            values="total_cost",
            names="regional_office_name",
            hole=0.4
        )
        fig2.update_traces(textposition="inside", textinfo="percent+label")
        st.plotly_chart(fig2, use_container_width=True)
    except Exception as e:
        st.error(f"Error loading regional data: {e}")

st.divider()

# ---------------------------
# Chart 3: Top 10 GP Practices
# ---------------------------
st.subheader("Top 10 GP Practices by Cost")

practice_query = f"""
    SELECT
        practice_name,
        practice_code,
        SUM(total_cost)  AS total_cost,
        SUM(total_items) AS total_items
    FROM ukb_dev_nhs_prescribing_db.practice_summary
    WHERE cast(year as varchar)  = '{selected_year}'
    AND   cast(month as varchar) = '{selected_month}'
    GROUP BY practice_name, practice_code
    ORDER BY total_cost DESC
    LIMIT 10
"""

try:
    practice_df = run_query(practice_query)
    fig3 = px.bar(
        practice_df,
        x="practice_name",
        y="total_cost",
        labels={"total_cost": "Total Cost (£)", "practice_name": "GP Practice"},
        color="total_cost",
        color_continuous_scale="Greens"
    )
    fig3.update_layout(
        xaxis_tickangle=-45,
        showlegend=False,
        coloraxis_showscale=False
    )
    st.plotly_chart(fig3, use_container_width=True)
except Exception as e:
    st.error(f"Error loading practice data: {e}")

st.divider()

# ---------------------------
# Raw data
# ---------------------------
st.subheader("Raw Data: Top 20 Practices")

if st.checkbox("Show raw data"):
    try:
        raw_query = f"""
            SELECT
                practice_name,
                practice_code,
                total_items,
                total_cost,
                total_nic,
                avg_cost_per_item
            FROM ukb_dev_nhs_prescribing_db.practice_summary
            WHERE cast(year as varchar)  = '{selected_year}'
            AND   cast(month as varchar) = '{selected_month}'
            ORDER BY total_cost DESC
            LIMIT 20
        """
        raw_df = run_query(raw_query)
        st.dataframe(raw_df, use_container_width=True)
    except Exception as e:
        st.error(f"Error loading raw data: {e}")

st.caption("Data source: NHS BSA Open Data Portal | Built with AWS Glue, Athena, Terraform & Streamlit")
