# Get-ADAnonymousAccessStatus

This script query the Active Directory to check the unicode value "dsHeuristics".

The 7th value of this settings determine if anonymous access is authorized or not in your environment.

So, if the value if "not defined", it's OK because equal 0. But if the value is 2, it's bad !
		 
# Example

```
        PS> .\Get-ADAnonymousAccessStatus.ps1
```

# Changelog
	        
**1.0.0 - 2018.01.25**

Initial Version