using System;
using System.IO;
using System.Text;
using System.Linq;

namespace LuaToHex
{
    class MainClass
    {
        public static void Main(string[] args)
        {
            var f = args[0].Replace(".", "_").Replace(" ", "_").Replace("/", "_").Replace(@"\", "_");
            Console.Write("char " + f + "[] = {");
            var xs = File.ReadAllBytes(args[0]);
            var ys = xs.Select((x) => "0x" + x.ToString("x2"));
            Console.Write(string.Join(", ", ys));
            Console.Write(", 0x00");
            Console.Write("};\n");
        }
    }
}
