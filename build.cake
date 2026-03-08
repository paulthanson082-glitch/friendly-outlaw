var target = Argument("target", "Test");
var configuration = Argument("configuration", "release");

//////////////////////////////////////////////////////////////////////
// TASKS
//////////////////////////////////////////////////////////////////////

Task("Clean")
    .WithCriteria(c => HasArgument("rebuild"))
    .Does(() =>
{
    StartProcess("swift", new ProcessSettings {
        Arguments = "package clean"
    });
});

Task("Build")
    .IsDependentOn("Clean")
    .Does(() =>
{
    var exitCode = StartProcess("swift", new ProcessSettings {
        Arguments = $"build -c {configuration}"
    });
    if (exitCode != 0)
        throw new Exception($"swift build failed with exit code {exitCode}");
});

Task("Test")
    .IsDependentOn("Build")
    .Does(() =>
{
    var exitCode = StartProcess("swift", new ProcessSettings {
        Arguments = "test"
    });
    if (exitCode != 0)
        throw new Exception($"swift test failed with exit code {exitCode}");
});

//////////////////////////////////////////////////////////////////////
// EXECUTION
//////////////////////////////////////////////////////////////////////

RunTarget(target);
