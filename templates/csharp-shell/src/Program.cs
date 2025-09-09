using System;
using System.Linq;
using Newtonsoft.Json;

namespace MyApp
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Console.WriteLine("Welcome to My C# Application!");
            Console.WriteLine("--------------------------------");
            
            var appInfo = new
            {
                Name = "MyApp",
                Version = "1.0.0",
                Framework = ".NET 8",
                Arguments = args
            };
            
            string json = JsonConvert.SerializeObject(appInfo, Formatting.Indented);
            Console.WriteLine("\nApplication Info:");
            Console.WriteLine(json);
            
            if (args.Length > 0)
            {
                Console.WriteLine($"\nReceived {args.Length} argument(s):");
                foreach (var arg in args.Select((value, index) => new { value, index }))
                {
                    Console.WriteLine($"  [{arg.index}]: {arg.value}");
                }
            }
            else
            {
                Console.WriteLine("\nNo arguments provided. Try running with: dotnet run -- arg1 arg2");
            }
            
            if (Environment.UserInteractive && !Console.IsInputRedirected)
            {
                Console.WriteLine("\nPress any key to exit...");
                Console.ReadKey();
            }
        }
    }
}