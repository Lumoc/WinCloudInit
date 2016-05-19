[CmdletBinding()]
param(
	$Config
)

if ($Config.Sysprep) {
	$Unattend = switch -Wildcard ((Get-CimInstance -class Win32_OperatingSystem).Caption) {
		'*2012 R2*' { 'unattend_2K12R2.xml' }
		'*2008 R2*' { 'unattend_2K8R2.xml' }
		default { throw 'OS unsupported' }
	}
	[xml]$UnattendXml = Get-Content (Join-Path $PSScriptRoot $Unattend)
	$Param = @{
		Xml = $UnattendXml
		Namespace = @{ns = 'urn:schemas-microsoft-com:unattend'}
	}

	(Select-Xml @Param -XPath '//ns:ComputerName').Node.InnerXml = $Config.HostName
	(Select-Xml @Param -XPath '//ns:AdministratorPassword/ns:Value').Node.InnerXml = $Config.Sysprep.AdminPassword
	(Select-Xml @Param -XPath '//ns:RegisteredOrganization').Node.InnerXml = $Config.Sysprep.Org
	(Select-Xml @Param -XPath '//ns:RegisteredOwner').Node.InnerXml = $Config.Sysprep.Owner
	(Select-Xml @Param -XPath '//ns:TimeZone').Node.InnerXml = $Config.Sysprep.TimeZone

	$AnswerFile = 'C:\Windows\Panther\unattend.xml'
	$UnattendXml.Save($AnswerFile)
	mkdir C:\Windows\Setup\Scripts -ea SilentlyContinue
	"del /Q /F $AnswerFile" > C:\Windows\Setup\Scripts\SetupComplete.cmd
	
	# switch to run under SYSTEM account
	$Credential = New-Object System.Management.Automation.PSCredential('SYSTEM',(New-Object System.Security.SecureString))
	Set-WinCloudInit -Credential $Credential
	'reboot' # system will be rebooted
	C:\Windows\system32\Sysprep\sysprep.exe /generalize /reboot /oobe /quiet /unattend:$AnswerFile
}