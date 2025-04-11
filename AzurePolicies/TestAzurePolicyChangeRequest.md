# Test Azure Policy Change Request

## Change Overview
This change request proposes the implementation of three new Azure Policies in our test subscriptions to enforce resource management and cost control measures. These policies will be applied to both sandbox and decomissions subscriptions first, and a separate change request will be made for an changes to regulare infrastructure.

## Policy Details

### 1. Approved Regions Policy
- **Purpose**: Restrict resource creation to approved regions (US, UK, EU, and Central India)
- **Effect**: Deny resource creation in non-approved regions
- **Scope**: All resource types except resource groups and global resources
- **Approved Regions**:
  - US: eastus, eastus2, westus, northcentralus, southcentralus
  - UK: uksouth, ukwest
  - EU: northeurope, westeurope
  - India: centralindia

### 2. Auto-Shutdown Policy
- **Purpose**: Automatically shut down resources during non-business hours
- **Effect**: Configure auto-shutdown for applicable resources
- **Scope**: 
  - Virtual Machines
  - VM Scale Sets
  - AKS Clusters
  - Databricks Workspaces
- **Configuration**:
  - Shutdown Time: 23:30 (local time)
  - Timezone: Region-specific (automatically determined)
  - Notification: 30 minutes before shutdown
  - Manual Start Required: Yes

### 3. Resource Tagging Policy
- **Purpose**: Enforce consistent tagging of resources
- **Effect**: Deny resource creation without required tags
- **Required Tags**:
  - Environment (e.g., "Sandbox", "Dev")
  - Owner (email)
  - Project
  - CostCenter

## Implementation Plan

### Phase 1: Policy Assignment
1. Create policy definitions in the management group
2. Assign policies to test subscriptions
3. Configure policy parameters:
   - Approved regions list
   - Shutdown time (23:30 local time)
   - Required tag names and values

### Phase 2: Testing
1. Create test resources in approved regions
2. Verify auto-shutdown configuration
3. Test resource creation with and without required tags
4. Verify region restrictions

## Impact Assessment

### Current State
- Test subscriptions are currently empty
- No existing resources to be affected
- No active development work in progress

### Expected Impact
- **Positive**:
  - Cost optimization through auto-shutdown
  - Better resource organization through enforced tagging
  - Improved compliance with regional requirements
- **Negative**:
  - None identified (no existing resources)

### Risk Mitigation
- Policies will be assigned in "Audit" mode initially
- Will be changed to "Deny" after successful testing
- Rollback plan: Remove policy assignments if issues arise

## Rollback Plan
1. Remove policy assignments from test subscriptions
2. Delete policy definitions if needed
3. No data loss expected as no resources exist

## Notes
- This change is considered low risk due to:
  - No existing resources in test subscriptions
  - Policies will be in audit mode initially
  - Easy rollback capability
  - No impact on production environments 