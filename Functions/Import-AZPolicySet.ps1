<#
I'm not sure if this is worth writing yet since it is pretty easy to use:

New-AzPolicySetDefinition -PolicyDefinition <PolicySetDefinition JSON> -Parameter <PolicySetParameters JSON> -Name <Name> -Description <Description>

The only reasons I'm considering writing this is because: 
- the export's policyDefinitionIds are going to reference the source locations instead of the destination locations so I could help the user through this
- I could automatically import all necessary policy definitions for the policy set

Parameters
        - PolicySetDefinition JSON
        - PolicySetParameters JSON
        - Name
        - Description
        - Where to import the policy definition to (management group name or subscription name)


#>