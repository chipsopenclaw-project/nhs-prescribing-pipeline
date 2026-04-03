# =============================================
# modules/athena/outputs.tf
# Exports workgroup name for Streamlit to use
# =============================================

output "workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.nhs.name
}
