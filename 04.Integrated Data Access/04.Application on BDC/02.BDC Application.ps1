$body = @{
    x =100
    y= 20
}


$temp = (kubectl get services --namespace mssql-cluster | Select-String "30777") -split " "
$ret = @()
foreach($local:v in $temp){
    if ($v -ne ""){
        $ret += $v
    }
}

Add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12

$User = $env:MGMTPROXY_LOGIN
$Password = $env:MGMTPROXY_LOGIN_PASSWORD
$cred = New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString -String $Password -AsPlainText -Force))

$token = (Invoke-WebRequest -Uri "https://$($ret[3]):30777/api/token" -Method Post -Credential $cred).Content | ConvertFrom-Json

$header = @{
  "Authorization" = ("Bearer {0}" -f $token.access_token);
  "content-type" = 'application/json'
}


$temp = (kubectl get services --namespace mssql-cluster | Select-String "30778") -split " "
$app = @()
foreach($local:v in $temp){
    if ($v -ne ""){
        $app += $v
    }
}


$ret = Invoke-WebRequest -Uri "https://$($app[3]):30778/api/app/add-app/v1/run" -Method Post -Headers $header -Body ($body | ConvertTo-Json)

$ret.Content | ConvertFrom-Json