// PwX Build Engine - PowerShell 7 host
// Gomulu payload.ps1 dosyasini benzersiz gecici klasore cikarir, PowerShell SDK ile calistirir,
// betigin cikis kodunu dondurur ve gecici klasoru temizler.
using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

namespace PwX.BuildHost
{
    internal static class Program
    {
        private const string PayloadResource = "PwX.payload.ps1";

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int MessageBoxW(IntPtr hWnd, string text, string caption, uint type);

        [STAThread]
        private static int Main(string[] args)
        {
            string workDir = null;
            try
            {
                workDir = Path.Combine(Path.GetTempPath(), "pwx-" + Guid.NewGuid().ToString("N"));
                Directory.CreateDirectory(workDir);
                string scriptPath = Path.Combine(workDir, "payload.ps1");
                ExtractPayload(scriptPath);

#if PWX_GUI
                return RunHidden(scriptPath, args);
#else
                return RunConsole(scriptPath, args);
#endif
            }
            catch (Exception ex)
            {
                ReportFatal("PwX host hatasi: " + ex.Message);
                return 1;
            }
            finally
            {
                try { if (workDir != null && Directory.Exists(workDir)) Directory.Delete(workDir, true); }
                catch { /* temizlik en iyi gayret esasli */ }
            }
        }

        private static void ExtractPayload(string target)
        {
            Assembly asm = Assembly.GetExecutingAssembly();
            using (Stream s = asm.GetManifestResourceStream(PayloadResource))
            {
                if (s == null) throw new InvalidOperationException("Gomulu betik bulunamadi.");
                using (FileStream fs = new FileStream(target, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                {
                    s.CopyTo(fs); // payload build sirasinda UTF-8 BOM ile yazilmistir
                }
            }
        }

#if !PWX_GUI
        // Konsol modu: pwsh -File davranisi (parametreler, stdout/stderr, cikis kodu)
        private static int RunConsole(string scriptPath, string[] userArgs)
        {
            try { Console.OutputEncoding = new UTF8Encoding(false); } catch { }

            string[] psArgs = new string[userArgs.Length + 6];
            psArgs[0] = "-NoLogo";
            psArgs[1] = "-NoProfile";
            psArgs[2] = "-ExecutionPolicy";
            psArgs[3] = "Bypass";
            psArgs[4] = "-File";
            psArgs[5] = scriptPath;
            Array.Copy(userArgs, 0, psArgs, 6, userArgs.Length);

            return Microsoft.PowerShell.ConsoleShell.Start(string.Empty, string.Empty, psArgs);
        }
#endif

#if PWX_GUI
        // GUI modu: konsol penceresi yok; STA runspace icinde calistirir.
        // Sinirlama (Roadmap Asama 3/4'te test edilecek): Read-Host gibi konsol etkilesimi desteklenmez.
        private static int RunHidden(string scriptPath, string[] args)
        {
            InitialSessionState iss = InitialSessionState.CreateDefault2();
            iss.ExecutionPolicy = Microsoft.PowerShell.ExecutionPolicy.Bypass;

            using (Runspace rs = RunspaceFactory.CreateRunspace(iss))
            {
                rs.ApartmentState = ApartmentState.STA;
                rs.ThreadOptions = PSThreadOptions.UseCurrentThread;
                rs.Open();

                using (PowerShell ps = PowerShell.Create())
                {
                    ps.Runspace = rs;
                    // Let PowerShell bind the original argument vector. Hand-parsing switches here
                    // breaks native forms such as -Name:value, negative values, and positional args.
                    ps.AddScript("param($scriptPath, $forwardArgs) & $scriptPath @forwardArgs")
                      .AddArgument(scriptPath)
                      .AddArgument(args);

                    try
                    {
                        ps.Invoke();
                    }
                    catch (RuntimeException ex)
                    {
                        ReportFatal(ex.Message);
                        return 1;
                    }

                    if (ps.HadErrors && ps.Streams.Error.Count > 0)
                    {
                        ReportFatal(ps.Streams.Error[0].ToString());
                        return 1;
                    }

                    object last = rs.SessionStateProxy.PSVariable.GetValue("LASTEXITCODE");
                    int code;
                    return (last != null && int.TryParse(last.ToString(), out code)) ? code : 0;
                }
            }
        }
#endif

        private static void ReportFatal(string message)
        {
#if PWX_GUI
            try { MessageBoxW(IntPtr.Zero, message, "PwX", 0x10); } catch { }
#else
            Console.Error.WriteLine(message);
#endif
        }
    }
}
