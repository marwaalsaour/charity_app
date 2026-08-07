@echo off
setlocal
cd /d "%~dp0.."

set "GRADLE_USER_HOME=%USERPROFILE%\.gradle"
set "JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStore=%CD%\android\certs\cacerts -Djavax.net.ssl.trustStorePassword=changeit"
set "GRADLE_OPTS=-I %CD%\android\rewrite-maven-central.gradle"

echo Using GRADLE_OPTS=%GRADLE_OPTS%
flutter run %*
