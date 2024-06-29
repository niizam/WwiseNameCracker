
# Wwise name cracker

Crack Wwise FNV-1 hashes (32-bit and 64-bit)
# Linux
## Build

To compile cracker (you need [LDC](https://github.com/ldc-developers/ldc) (LLVM D compiler), you can use others but they might not be as performant)

```
$ ./build.bat
```

You can also compile with Profile-Guided Optimizations (PGO) by specifying input arguments that will be used for optimization:

```
$ ./build.sh sample-hashes.txt sample-names.txt
```

(You might want to pass `--expand 0` to save time)

## Usage

1. Collect hashes from .pck files
```
$ find GamePath -iname '*.pck' -print0 | xargs -0 -I!!! -n 1 quickbms -l wwiser-utils/scripts/wwise_pck_extractor.bms !!! | tr -s '[:blank:]' | cut -d ' ' -f 4 | cut -d '/' -f 2 | cut -d '.' -f 1 | sort -u > hashes.txt
```

2. Filter name string list - this will drastically reduce search space. You can skip this step if you're using names from `wwiser-utils`.
```
$ ./crackNames --filter hashes.txt strings.txt > hash_names.txt
```

3. Convert from `hash_names.txt` (it contains `hash:name` pairs) to only `names.txt`. This step is required only if you did previous (2nd) step.

Need to select only most suitable names, but most likely case is there aren't any duplicates.
```
$ cut -d ':' -f 2 hash_names.txt | sort > names.txt
$ uniq -d names.txt
(should be empty, no output)
```

4. Crack hashes (you need atleast some names since those will be used as patterns)
```
$ ./crackNames hashes.txt names.txt > hash_cnames.txt
```

(You can use `wwiser-utils/wwnames/GameName (External).txt`)

4. Remove duplicates and update names

You can inspect them with
```
$ cat hash_cnames.txt | cut -d ':' -f 1 | sort | uniq -d | xargs -I!!! grep !!! hash_cnames.txt
```

Then if there aren't duplicates

```
cat hash_cnames.txt | cut -d ':' -f 2 | sort -u > "wwiser-utils/wwnames/GameName (External).txt"`
```
# Windows
## Build

To compile cracker (you need [LDC](https://github.com/ldc-developers/ldc) (LLVM D compiler), you can use others but they might not be as performant).
Or you can use [Chocolatey](https://chocolatey.org/install).
```
choco install ldc
```
Then build it.
```powershell
$ .\build.bat
```

You can also compile with Profile-Guided Optimizations (PGO) by specifying input arguments that will be used for optimization:

```powershell
$ .\build.bat sample-hashes.txt sample-names.txt
```

(You might want to pass `--expand 0` to save time)

## Usage

1. Collect hashes from .pck files
```powershell
$PSDefaultParameterValues['*:Encoding'] = 'Default'
# Get all .pck files in the specified directory
Get-ChildItem -Path "C:\path\to\pck\files" -Recurse -Filter *.pck | ForEach-Object {
    # Run quickbms on each file and capture the output
    $output = & "C:\path\to\quickbms.exe" -l "C:\path\to\wwiser-utils\scripts\wwise_pck_extractor.bms" $_.FullName
    
    # Check if $output is not empty
    if ($output) {
        # Process the output
        $output -split "`n" | ForEach-Object {
            # Extract filename from the line
            $filename = ($_ -split ' ')[-1]
            # Extract basename without extension
            $basename = [System.IO.Path]::GetFileNameWithoutExtension($filename)
            # Output the basename
            Write-Output $basename
        }
    } else {
        Write-Output "No output from quickbms for file: $($_.FullName)"
    }
} | Sort-Object -Unique | Out-File -FilePath "hashes.txt"
```

2. Filter name string list - this will drastically reduce search space. You can skip this step if you're using names from `wwiser-utils`.
```powershell
$PSDefaultParameterValues['*:Encoding'] = 'Default'
.\crackNames --filter hashes.txt strings.txt | Out-File -FilePath "hash_names.txt"
```

3. Convert from `hash_names.txt` (it contains `hash:name` pairs) to only `names.txt`. This step is required only if you did previous (2nd) step.

Need to select only most suitable names, but most likely case is there aren't any duplicates.
```powershell
$PSDefaultParameterValues['*:Encoding'] = 'Default'
# Extract the second field using ':' delimiter and sort the output
Get-Content -Path "hash_names.txt" | ForEach-Object {
    $_.Split(':')[1].Trim()
} | Sort-Object | Out-File -Encoding  -FilePath "names.txt"

# Find duplicate lines in names.txt
Get-Content -Path "names.txt" | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    $_.Group[0].Name
} | Out-File -FilePath "duplicate_names.txt"

# should be empty, no output
```

4. Crack hashes (you need atleast some names since those will be used as patterns)
```powershell
$PSDefaultParameterValues['*:Encoding'] = 'Default'
.\crackNames hashes.txt names.txt | Out-File -FilePath hash_cnames.txt
```

(You can use `wwiser-utils/wwnames/GameName (External).txt`)

4. Remove duplicates and update names

You can inspect them with
```powershell
$PSDefaultParameterValues['*:Encoding'] = 'Default'
# Step 1: Find unique duplicate entries based on the first field
$uniqueDuplicates = Get-Content -Path "hash_cnames.txt" | ForEach-Object {
    $_ -split ':' | Select-Object -First 1
} | Sort-Object | Get-Unique -AsString

# Step 2: Use Select-String to filter lines containing each duplicate entry
$uniqueDuplicates | ForEach-Object {
    Select-String -Path "hash_cnames.txt" -Pattern $_
}
```

Then if there aren't duplicates

```powershell
$PSDefaultParameterValues['*:Encoding'] = 'Default'
# Read hash_cnames.txt, extract second field using ':' delimiter, sort uniquely, and save to a file
Get-Content -Path "hash_cnames.txt" | ForEach-Object {
    $_ -split ':' | Select-Object -Index 1
} | Sort-Object -Unique | Out-File -FilePath "wwiser-utils\wwnames\GameName (External).txt"

```

## Options

There are several options you can adjust:
```
$ ./crackNames --help
Usage: ./crackNames [options] [hashes.txt] names.txt [names2.txt ...]
-f    --filter Filter provided names, listing ones that matched hashes
-p  --patterns Show name patterns
-g --generated List all generated names
-j      --json Show internal raw info in JSON
-e    --expand Increase name search by this amount (default 5)
-n       --new List only new names without those that already matched
-r     --roman Recognize Roman Numerals
-b     --32bit Look for names for 32-bit FNV-1 hashes
-t   --threads Number of threads to use (default number of CPU cores)
-h      --help This help information.
```

Use `--expand` to reduce or increase search space.

And if you think there might be Roman Numerals used then pass `--roman` - it will try names with III, IV, V, VI and so on.

You can also inspect recognized patterns which can be useful for diff'ing:
```
$ ./crackNames --patterns names.txt
%s/voice/chapter%d_%d_soldier%c_%d.wem:{English;Japanese}[0-3][0-15]{A;AB;AC;B;V;W}[201-209]
%s/voice/archive_%s_%d.wem:{English;Japanese}{guinaifen;player}[1-22]
```

## Crack event names (32-bit FNV-1 hashes)

// TODO - Need to document it and decide on best workflow
