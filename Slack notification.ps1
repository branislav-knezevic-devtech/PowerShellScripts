function Slack-Rich-Notification ($notification)
{
    $payload = @{
        channel = $OctopusParameters['Channel']
        username = $OctopusParameters['Username'];
        icon_url = $OctopusParameters['IconUrl'];
        attachments = @(
            @{
            fallback = $notification["fallback"];
            color = $notification["color"];
            fields = @(
                @{
                title = $notification["title"];
                title_link = $notification["title_link"];
                value = $notification["value"];
                });
            };
        );
    }

    Invoke-RestMethod -Method POST -Body ($payload | ConvertTo-Json -Depth 4) -Uri $OctopusParameters['HookUrl']  -ContentType 'application/json'
}

$IncludeMachineName = [boolean]::Parse($OctopusParameters['IncludeMachineName']);
if ($IncludeMachineName) {
    $MachineName = $OctopusParameters['Octopus.Machine.Name'];
    if ($MachineName) {
      $FormattedMachineName = "($MachineName)";
    }
}

if ($OctopusParameters['Octopus.Deployment.Error'] -eq $null){
    Slack-Rich-Notification @{
        title = "Success";
        title_link = "$OctopusWebBaseUrl$OctopusWebDeploymentLink";
        value = "Deploy <$OctopusWebBaseUrl$OctopusWebProjectLink|$OctopusProjectName> release <$OctopusWebBaseUrl$OctopusWebReleaseLink|$OctopusReleaseNumber> to $OctopusEnvironmentName $OctopusActionTargetRoles $OctopusDeploymentTenantName $FormattedMachineName";
        fallback = "Deployed $OctopusProjectName release $OctopusReleaseNumber to $OctopusEnvironmentName successfully";
        color = "good";
    };
} else {
    Slack-Rich-Notification @{
        title = "Failed";
        title_link = "$OctopusWebBaseUrl$OctopusWebDeploymentLink";
        value = "Deploy <$OctopusWebBaseUrl$OctopusWebProjectLink|$OctopusProjectName> release <$OctopusWebBaseUrl$OctopusWebReleaseLink|$OctopusReleaseNumber> to $OctopusEnvironmentName $OctopusActionTargetRoles $OctopusDeploymentTenantName $FormattedMachineName";
        fallback = "Failed to deploy $OctopusProjectName release $OctopusReleaseNumber to $OctopusEnvironmentName";
        color = "danger";
    };
}