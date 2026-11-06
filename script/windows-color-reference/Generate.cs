using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;

// This is a build-time reference probe, not a runtime app dependency.
// The Windows app's ColorDisplayNameHelper calls this classifier and
// resolves the resulting string ID from the XAML localized resources.
public static class ColorReference
{
    [UnmanagedFunctionPointer(CallingConvention.Winapi)]
    delegate int Classify(uint color, out int resourceId);

    [DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr LoadLibraryExW(string file, IntPtr reserved, uint flags);

    [DllImport("user32", CharSet = CharSet.Unicode)]
    static extern int LoadStringW(IntPtr library, uint id, StringBuilder value, int length);

    [DllImport("kernel32")]
    static extern bool FreeLibrary(IntPtr library);

    public static void Generate(string release, string output)
    {
        var native = NativeLibrary.Load(Path.Combine(release, "Microsoft.UI.Xaml.Internal.dll"));
        var mui = LoadLibraryExW(Path.Combine(release, "en-us", "Microsoft.ui.xaml.dll.mui"), IntPtr.Zero, 2);
        if (mui == IntPtr.Zero) throw new System.ComponentModel.Win32Exception();
        try
        {
            var classify = Marshal.GetDelegateForFunctionPointer<Classify>(
                NativeLibrary.GetExport(native, "ColorHelper_ToDisplayNameId"));
            var table = new byte[1 << 24];
            var indices = new Dictionary<int, byte>();
            var names = new List<string>();
            for (int rgb = 0; rgb < table.Length; rgb++)
            {
                // Windows.UI.Color is four bytes A, R, G, B in memory.
                uint color = (uint)(255 | ((rgb >> 16) << 8) | ((rgb & 0xff00) << 8) | ((rgb & 0xff) << 24));
                Marshal.ThrowExceptionForHR(classify(color, out int resource));
                if (!indices.TryGetValue(resource, out byte index))
                {
                    var name = new StringBuilder(128);
                    if (LoadStringW(mui, (uint)resource, name, name.Capacity) == 0)
                        throw new InvalidOperationException("Missing XAML string for ID " + resource);
                    index = checked((byte)names.Count);
                    indices.Add(resource, index);
                    names.Add(name.ToString());
                }
                table[rgb] = index;
            }
            if (!String.Equals(names[table[0]], "Black", StringComparison.OrdinalIgnoreCase) ||
                !String.Equals(names[table[0xffffff]], "White", StringComparison.OrdinalIgnoreCase) ||
                !String.Equals(names[table[0xff0000]], "Red", StringComparison.OrdinalIgnoreCase) ||
                !String.Equals(names[table[0x0000ff]], "Blue", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("XAML color-name sentinels failed.");
            Directory.CreateDirectory(output);
            File.WriteAllBytes(Path.Combine(output, "rgb.bin"), table);
            File.WriteAllText(Path.Combine(output, "names.json"), JsonSerializer.Serialize(names));
            Console.WriteLine($"Classified {table.Length} RGB values into {names.Count} Windows resource IDs.");
        }
        finally
        {
            FreeLibrary(mui);
            NativeLibrary.Free(native);
        }
    }
}
