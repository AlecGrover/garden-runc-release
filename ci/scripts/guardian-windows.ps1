$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

cd gr-release-develop

$env:PWD = (Get-Location)
$env:GOPATH = ${env:PWD} + "\src\gopath"
$env:PATH = $env:GOPATH + "/bin;C:/go/bin;" + $env:PATH

Write-Host "Installing Ginkgo"
go.exe install ./src/gopath/src/github.com/onsi/ginkgo/ginkgo
if ($LastExitCode -ne 0) {
    throw "Ginkgo installation process returned error code: $LastExitCode"
}

$guardian_path = ${env:GOPATH} + "/src/code.cloudfoundry.org/guardian"
cd ${guardian_path}

go version
go vet ./...
Write-Host "compiling test process: $(date)"

$env:GARDEN_TEST_ROOTFS = "N/A"
ginkgo -r -nodes 8 -race -keepGoing -failOnPending -skipPackage "dadoo,gqt,kawasaki,locksmith,socket2me,signals,runcontainerd\nerd"
if ($LastExitCode -ne 0) {
    throw "Ginkgo run returned error code: $LastExitCode"
}
ginkgo -r -nodes 8 -race -keepGoing -failOnPending -randomizeSuites -randomizeAllSpecs -skipPackage "dadoo,kawasaki,locksmith" -focus "Runtime Plugin" gqt
Exit $LastExitCode
