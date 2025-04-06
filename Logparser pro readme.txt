# Log Parser Bash Script


## Description

This Bash script is designed to parse and filter web server log files stored in CSV format. It validates user inputs, processes the log file based on given filters, and outputs the results into a structured CSV file. Users can optionally compress the result into a ZIP file.

This tool is especially useful for quickly analyzing large logs to extract entries matching specific HTTP methods, URLs, IPs, or status codes.

---

## How the Code Works

### 1. **Modes of Operation**
- **Default Mode** (no arguments):  
  Prompts the user to:
  - Enter the input CSV file path.
  - Enter the number of rows to skip from the end (for partial parsing).
  - Provide an output filename.

- **Flag Mode** (with arguments):  
  Accepts combinations of `-s`, `-d`, and `-z` flags:
  - `-s <term>`: Search for a single term.
  - `-d <term1,term2>`: Search for rows containing **both** terms.
  - `-z`: Compress output as a `.zip` file.

### 2. **Input Validation**
- Ensures the log file:
  - Exists.
  - Has a `.csv` extension.
  - Contains a valid header row: `IP,Date,Method,URL,Protocol,Status`.
- Prompts the user up to 3 times if an invalid file is entered.

### 3. **Parsing the File**
- Uses `awk` and `grep` to:
  - Filter matching rows based on search terms.
  - Skip trailing rows if user requests it (default mode).
  - Clean and format output properly.

### 4. **Output Handling**
- Constructs a timestamped filename like `results_file_20250406_103010.csv`.
- Writes a clean header and filtered rows into the output file.
- Optionally compresses the file into `.zip` using the `zip` utility.

### 5. **Error Handling**
- Provides error messages for invalid input.
- Prevents overwriting output files without user confirmation.
- Automatically deletes empty output files and informs the user.

---

## How to Use

### 1. **Make the Script Executable**
```bash
chmod +x log_parser.sh
```

### 2. **Run the Script**

#### **Option A: Default Manual Mode**
```bash
./log_parser.sh
```
You will be prompted to:
- Enter the input CSV log filename.
- Choose how many rows to skip from the end (optional).
- Provide a name for the output CSV file.

This mode does not use command-line flags. It's useful for manual review or small data sets.

---

#### **Option B: Flag Mode**

##### Single Term Search
```bash
./log_parser.sh -s "404"
```
Searches for all rows containing `"404"` (e.g., status code).

##### Double Term Search
```bash
./log_parser.sh -d "GET,200"
```
Returns only rows that contain **both** `"GET"` and `"200"`.

##### Search and Compress
```bash
./log_parser.sh -s "POST" -z
```
or
```bash
./log_parser.sh -d "admin,success" -z
```
Creates a ZIP file from the result CSV.

---

## Example Workflow

```bash
./log_parser.sh -d "admin,login" -z
```

- Validates input log file structure and existence.
- Searches for rows with **both** "admin" and "login".
- Outputs matched rows into `results_file_YYYYMMDD_HHMMSS.csv`.
- Compresses the output to `results_file_YYYYMMDD_HHMMSS.zip`.

---

## Output Structure

Output CSV files follow this header:
```
IP,Date,Method,URL,Protocol,Status
```

Example output:
```
192.168.1.10,2025-04-05 10:15:20,GET,/admin,HTTP/1.1,200
203.0.113.50,2025-04-05 11:12:32,POST,/login,HTTP/1.1,403
```

If no matches are found, the output file is deleted, and the user is notified.

---

## Dependencies

Ensure the following Unix utilities are installed:
- `awk`
- `sed`
- `grep`
- `zip` (if using `-z`)

These are typically available by default on Linux/macOS systems.

---

## Known Limitations

- Only CSV log files with the correct header format are accepted.
- Cannot combine `-s` and `-d`; only one search mode per run.
- Skipping rows from the end is only supported in default (manual) mode.
- Not designed for real-time or streaming log input.

---


