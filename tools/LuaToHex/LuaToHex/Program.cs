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
            Console.Write("char lcode[] = {");
            var xs = File.ReadAllBytes(args[0]);
            var ys = xs.Select((x) => "0x" + x.ToString("x2"));
            Console.Write(string.Join(", ", ys));
            Console.Write(", 0x00");
            Console.Write("};");
        }
    }
}
