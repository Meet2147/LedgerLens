@ECHO OFF
SET APP_HOME=%~dp0
IF NOT EXIST "%APP_HOME%gradle\wrapper\gradle-wrapper.jar" (
  ECHO Gradle wrapper JAR is not checked in. Generate it locally with "gradle wrapper" before building.
  EXIT /B 1
)
java -classpath "%APP_HOME%gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain %*
