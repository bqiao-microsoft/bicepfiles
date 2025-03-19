param workspace string

@description('Unique id for the scheduled alert rule')
@minLength(1)
param analytic_id string = '03006c6b-d532-4799-baac-0ab52bac8482'

resource workspace_Microsoft_SecurityInsights_analytic_id 'Microsoft.OperationalInsights/workspaces/providers/alertRules@2020-01-01' = {
  name: '${workspace}/Microsoft.SecurityInsights/${analytic_id}'
  kind: 'Scheduled'
  location: resourceGroup().location
  properties: {
    description: 'Malware authors will sometimes hardcode user agent string values when writing the network communication component of their malware.\nMalformed user agents can be an indication of such malware.'
    displayName: 'Malformed user agent bicep'
    enabled: false
    query: '\n(union isfuzzy=true\n(OfficeActivity | where UserAgent != ""),\n(OfficeActivity\n| where RecordType in ("AzureActiveDirectory", "AzureActiveDirectoryStsLogon")\n| extend OperationName = Operation\n| parse ExtendedProperties with * \'User-Agent\\\\":\\\\"\' UserAgent2 \'\\\\\' *\n| parse ExtendedProperties with * \'UserAgent",      "Value": "\' UserAgent1 \'"\' *\n| where isnotempty(UserAgent1) or isnotempty(UserAgent2)\n| extend UserAgent = iff( RecordType == \'AzureActiveDirectoryStsLogon\', UserAgent1, UserAgent2)\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by UserAgent, SourceIP = ClientIP, Account = UserId, Type, RecordType, Operation\n),\n(AzureDiagnostics\n| where ResourceType =~ "APPLICATIONGATEWAYS" \n| where OperationName =~ "ApplicationGatewayAccess" \n| extend ClientIP = columnifexists("clientIP_s", "None"), UserAgent = columnifexists("userAgent_s", "None")\n| where UserAgent != \'-\'\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by UserAgent, SourceIP = ClientIP,  requestUri_s, httpMethod_s, host_s, requestQuery_s, Type\n),\n(\nW3CIISLog\n| where isnotempty(csUserAgent)\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by UserAgent = csUserAgent, SourceIP = cIP, Account = csUserName, Type, sSiteName, csMethod, csUriStem\n),\n(\nAWSCloudTrail\n| where isnotempty(UserAgent)\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by UserAgent, SourceIP = SourceIpAddress, Account = UserIdentityUserName, Type, EventSource, EventName\n),\n(SigninLogs\n| where isnotempty(UserAgent)\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by UserAgent, SourceIP = IPAddress, Account = UserPrincipalName, Type, OperationName, tostring(LocationDetails), tostring(DeviceDetail), AppDisplayName, ClientAppUsed\n),\n(AADNonInteractiveUserSignInLogs \n| where isnotempty(UserAgent)\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by UserAgent, SourceIP = IPAddress, Account = UserPrincipalName, Type, OperationName, tostring(LocationDetails), tostring(DeviceDetail), AppDisplayName, ClientAppUsed\n)\n)\n// Likely artefact of hardcoding\n| where UserAgent startswith "User" or UserAgent startswith \'\\"\'\n// Incorrect casing\nor (UserAgent startswith "Mozilla" and not(UserAgent containscs "Mozilla"))\n// Incorrect casing\nor UserAgent containscs  "(Compatible;"\n// Missing MSIE version\nor UserAgent matches regex @"MSIE\\s?;"\n// Incorrect spacing around MSIE version\nor UserAgent matches regex  @"MSIE(?:\\d|.{1,5}?\\d\\s;)"\n| extend timestamp = StartTime, IPCustomEntity = SourceIP, AccountCustomEntity = Account\n'
    queryFrequency: 'P1D'
    queryPeriod: 'P1D'
    severity: 'Medium'
    suppressionDuration: 'PT1H'
    suppressionEnabled: false
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
    tactics: [
      'InitialAccess'
      'CommandAndControl'
      'Execution'
    ]
  }
}
