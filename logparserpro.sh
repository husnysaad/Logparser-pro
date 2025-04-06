#!/bin/bash



# function to display usage instructions for the script and to be called upon when needed
usage() {
    echo "Usage: $0 [-s search_term | -d search_term1,search_term2] [-z]"
    echo "  -s search_term: Filter rows containing a single search term."
    echo "  -d search_term1,search_term2: Filter rows containing both search terms."
    echo "  -z: Compress the results into a zip file (must be used with -s or -d)."
    echo "  Default mode: If no flags are provided, the script will request input and output file names."
    exit 1  # Exit the script after displaying usage information
}

# function to validate the CSV input file with a maximum of 3 attempts for user convinience 
validate_input_file() {
    attempts=0  # initialize the attempt counter
    max_attempts=3  # set the maximum number of attempts allowed to 3
    while [[ $attempts -lt $max_attempts ]]; do  # while attempts counter is less than max attempts run the loop
        read -p "Enter the name of the log file to parse (must be a CSV file): " input_file # read -p to assign the input to the variable input_file
        # check if the file exists and has a .csv extension
        if [[ -f "$input_file" && "$input_file" == *.csv ]]; then # -f to check if the file is avaiable in the directory and if it is a csv file
            return 0  # exit the function successfully if the input file is valid
        else
            ((attempts++))  # increment the attempts counter
            echo "Error: '$input_file' is not a valid CSV file. Attempts remaining: $((max_attempts - attempts))" # show the number of attempts by substracting max attempts by current attemtps
        fi
        # check if the maximum attempts have been reached
        if [[ $attempts -eq $max_attempts ]]; then #if attempts equal to max attempts then proceed to the end the loop with a prompt
            echo "mximum attempts reached. Exiting."
            exit 1  # eit the script if the maximum attempts are reached
        fi
    done #end of while loop
}


#The default_mode function is designed to guide the user through a series of prompts to obtain the names of the input and output files needed for the script to
#function correctly. The function ensures that:
#the input file is validated to be an existing CSV file.
#The output file name provided by the user ends with .csv.
#if the output file already exists, the user is given the option to overwrite it or cancel the operation.


# function for default mode when no flags are provided
default_mode() {
    echo "Entering default mode... Please provide input and output file names."  # message to infrom the user entry into default mode
    validate_input_file  # call the input file validation function
    read -p "Enter the name of the output file to create (should be a CSV file): " output_file # store the outputfile name into the outfile name using read -p
    # check if the output file has a .csv extension
    if [[ "$output_file" != *.csv ]]; then # if the outputfile is not a csv then promtp the error
        echo "error: Output file '$output_file' is not a CSV file."
        exit 2  # exit if the output file is not valid
    fi
    # check if the output file already exists
    if [[ -f "$output_file" ]]; then #-f to check if the file is avaialble in the directory
        read -p "Output file '$output_file' already exists. Overwrite? (y/n): " overwrite # hold the user reposonse in overwrite
        # handle the user's response regarding overwriting the existing file
        case $overwrite in #beging a case to check users overwrite repsonse
            [Yy]* ) echo "Overwriting $output_file...";;  # if the overwrite variable starts with y or Y 
            [Nn]* ) echo "Operation canceled."; exit 0;;  # if the response starts with N or N
            * ) echo "Invalid input. Operation canceled."; exit 0;;  # handle invalid input
        esac #end case
    fi

    # write the CSV header to the output file 
    echo "IP,Date,Method,URL,Protocol,Status" > "$output_file" #direct the echo to the outputfile
    

    #-e '1d':1d: Deletes the first line of the input file ($input_file). This is to remove the header row, which often contains column names rather than data.
    #-e 's/\[//g':s/\[//g: This substitutes (removes) all instances of the character [ from the file. The g flag ensures that every occurrence of [ is removed throughout each line.
    #-r -e 's/:[0-9]+:[0-9]+:[0-9]+//g':-r: Enables extended regular expressions in sed.
    #s/:[0-9]+:[0-9]+:[0-9]+//g: This removes the time part in the format :hh:mm:ss from the input. The regex :[0-9]+:[0-9]+:[0-9]+ looks for a colon (:) followed by one or more digits (representing hours, minutes, and seconds), and removes this part of the string.
    #-e 's/\?.* /,/g':s/\?.* /,/g: This replaces any part of the string that starts with a question mark (?) and continues until a space ( ) with a comma (,). This is to dealing with query strings in URLs, removing everything after the ?.
    #-e 's/ \//,/g':s/ \//,/g: This replaces any space followed by a forward slash (/) with a comma (,). This will deal with parts of the URL structure where spaces might separate components, like GET /path/to/resource.
    #-e "s/ /,/g":s/ /,/g: This replaces all remaining spaces in the line with commas. This effectively converts the input data into a CSV-like format, where fields are separated by commas.



    # format the CSV file using sed
    formatted_lines=$(sed -e '1d' -e 's/\[//g' -r -e 's/:[0-9]+:[0-9]+:[0-9]+//g' -r -e 's/\?.* /,/g' -r -e 's/ \//,/g' -r -e "s/ /,/g" "$input_file")

    # check if there are any formatted lines to write
    if [[ -n "$formatted_lines" ]]; then #-n used to check if the string is not zero
        echo "$formatted_lines" >> "$output_file"  # append formatted lines to the output file
    fi

    #wc -l "$output_file": This counts the number of lines in the file specified by $output_file. The wc command stands for "word count," but when used with the -l flag, it counts the number of lines.
    #| awk '{print $1 - 1}': The output of wc -l is piped to awk. In this case, awk extracts the first field ($1, which is the number of lines), subtracts 1 from it, and prints the result. The subtraction of 1 is done to exclude the header row
    #echo "$count records processed and written to $output_file":
    #This simply prints a message indicating how many records were processed and written to the output file.
    #The $count variable holds the number of records (excluding the header), so the message will display something like
        

 #count the number of records processed and written to the output file
    count=$(wc -l "$output_file" | awk '{print $1 - 1}')
    echo "$count records processed and written to $output_file"  # output the count of processed records
}

# initialize variables
single_search=""  # to hold a single search term if -s is used
double_search=()  # to hold two search terms if -d is used
zip_flag=false  # boolean variable to hold the zip flag
base_output_file="results_file"  # base name for the output file


#s):This case handles the -s option for a single search term.
#if [[ "$OPTARG" == "," ]]; then:
#This checks if the argument for the -s option (stored in OPTARG) contains a comma. If it does, it implies that the user provided multiple terms instead of a single one.
#If true, an error message is displayed, and the usage function is called to show how to use the script correctly.

#the -d option for double search terms.
#if [[ -n "$single_search" ]]; then:
#This checks if single_search is not empty (i.e., the -s option was also used). If it was, an error message is displayed, and the usage function is called, since using both options simultaneously is not allowed.
#IFS=',' read -r term1 term2 <<< "$OPTARG":
#This line splits the argument for the -d option (which should be two terms separated by a comma) into two separate variables, term1 and term2. The IFS variable (Internal Field Separator) is set to a comma to facilitate the splitting.
#if [[ -z "$term1" || -z "$term2" ]]; then:
#This checks if either term1 or term2 is empty, which would indicate that the user did not provide two valid terms. An error message is displayed, and the usage function is called if this condition is met.
#double_search=("$term1" "$term2"):
#If valid, both terms are stored in the double_search array.

#z):This case handles the -z option, which is a flag indicating that the output should be compressed into a zip file.
#zip_flag=true:
#The zip_flag variable is set to true, indicating that the user requested zipping of the output.
#
#\?):This case handles invalid options that do not match any of the specified options.
#echo "Error: invalid flag -$OPTARG" >&2:
#an error message is printed to standard error indicating which flag is invalid.
#
#:):this case handles situations where an option requiring an argument (like -s or -d) is provided without one.


# parse command line options
while getopts ":s:d:z" opt; do # the string ":s:d:z" specifies the options that the script accepts
    case $opt in #open case for each option held in opt
        s)  # handle the -s option for single search term
            # check if the argument is a valid single term (not a comma-separated list)
            if [[ "$OPTARG" == "," ]]; then #checks if the comma is used to made 2 different arguemnts
                echo "Error: The -s option requires a single search term, not a list."
                usage  # display usage and exit if invalid input is provided
            fi
            single_search="$OPTARG"  # store the single search term
            ;;
        d)  # handle the -d option for double search terms
            if [[ -n "$single_search" ]]; then #single search is emtpy
                echo "Error: You cannot use both -s and -d options simultaneously."
                usage  # display usage and exit if conflicting options are found
            fi
            # split the search terms by comma and store them in the double_search array
            IFS=',' read -r term1 term2 <<< "$OPTARG" #set the internal field seperator to comma
            if [[ -z "$term1" || -z "$term2" ]]; then 
                echo "error: The -d option requires two search terms separated by a comma."
                usage  # display usage and exit if invalid input is provided
            fi
            double_search=("$term1" "$term2")  # store the two search terms
            ;;
        z)  # handle the -z option for zipping the output
            zip_flag=true  # set the zip flag to true
            ;;
        \?)  # handle invalid options
            echo "Error: invalid flag -$OPTARG" >&2 #- is concatenated with $OPTARG, which holds the option character (the flag) that was passed by the user and redirect to the standerr
            usage  # Display usage and exit
            ;;
        :)  # handle missing arguments for options
            echo "Error: Option -$OPTARG requires an argument." >&2
            usage  # display usage and exit
            ;;
    esac #end of case
done

# shift off options processed by getopts
shift $((OPTIND - 1)) #shift parameters to the left to give that number of options that have been processed

# default mode if no flags are provided
if [[ -z "$single_search" && -z "${double_search[0]}" && $zip_flag == false ]]; then #-z check if the variables are empty and check if the zip flag is false 
    default_mode  # call the default mode function
    exit 0  # Exit after processing in default mode
fi

# validate the input file for search/filter mode
validate_input_file
echo "Processing log file: $input_file"  # display the input file being processed
count=0  # initialize count for matching lines
matching_lines=()  # initialize an array to hold matching lines

#-F',' sets the field separator to a comma, which is typical for CSV files
#-v term="$single_search" assigns the value of the single_search variable to the term variable within the awk script.
#NR > 1 skips the first line of the file (usually the header) since we are only interested in the data rows.
#if ($0 ~ term) checks if the entire line ($0) matches the search term. If it does, print $0 outputs the matching line.
#the result is stored in the variable matching_lines, which contains all lines from the input file that include the specified single search term.
#
#for double search
#-F',' and the variable assignments -v term1="${double_search[0]}" -v term2="${double_search[1]}" work similarly as explained before.
#if ($0 ~ term1 && $0 ~ term2) checks if the line matches both search terms. If both conditions are true, print $0 outputs the matching line.
#The result is stored in matching_lines, which now contains all lines from the input file that include both specified search terms.
#
#

# filtering logic based on the search options
if [[ -n "$single_search" ]]; then
    # filter lines containing the single search term using awk
    matching_lines=$(awk -F',' -v term="$single_search" 'NR > 1 { if ($0 ~ term) { print $0 } }' "$input_file")
elif [[ -n "${double_search[0]}" ]]; then #this line checks if the first element of the double_search array is non-empty. This indicates that the user has provided two search terms using the -d option.
    # filter lines containing both search terms using awk
    matching_lines=$(awk -F',' -v term1="${double_search[0]}" -v term2="${double_search[1]}" 'NR > 1 { if ($0 ~ term1 && $0 ~ term2) { print $0 } }' "$input_file")
fi

#the pipe operator | takes the output from the previous command (echo "$matching_lines") and passes it as input to the grep command.
#the grep -c option is used to count the number of lines that match a given pattern.
#the pattern [^[:space:]] is a regular expression that matches any line containing at least one character that is not a whitespace character.

# count the number of matching lines found
count=$(echo "$matching_lines" | grep -c '[^[:space:]]')

# process the output file if matching lines are found
if [[ $count -gt 0 ]]; then # check if the value is greater than zero
    timestamp=$(date +%Y%m%d%H%M%S)  # generate a timestamp for unique output filenames
    output_file="${base_output_file}_${timestamp}.csv"  # create the output filename
    # write the header to the output file
    echo "IP,Date,Method,URL,Protocol,Status" > "$output_file" #push the header into the outputfile first
    echo "$matching_lines" >> "$output_file"  # write matching lines to the output file
    echo "$count matching rows found and written to $output_file"  # output the count of matching rows

    #-r: Enables extended regular expressions (ERE), allowing more complex regex patterns without needing to escape certain characters (like +, ?)
    #-i: Edits the file in place, meaning that sed will modify the original file directly without creating a backup
    #-e: Allows you to specify multiple editing commands
       
    
    # format the file in-place using sed
    sed -i -e 's/\[//g' -r -e 's/:[0-9]+:[0-9]+:[0-9]+//g' -r -e 's/\?.* /,/g' -r -e 's/ \//,/g' -r -e "s/ /,/g" "$output_file"


    #${output_file%.csv}:
    #This part uses parameter expansion in Bash to remove the .csv extension from the output_file variable.
    #If output_file was set to results.csv, ${output_file%.csv} would evaluate to results.
    #echo "Results compressed into ${output_file%.csv}":
    #The echo command then constructs a string that indicates the output file location, excluding the file extension.
    #The complete message printed would be something like Results compressed into results, indicating that the results have been successfully compressed.
    


    # check if the zip flag is set to compress the output file
    if $zip_flag; then #if zip flag variable is true then
        zip "${output_file%.csv}.zip" "$output_file"  # create a zip archive of the output file
        echo "Results compressed into ${output_file%.csv}.zip."  # inform the user about the zip file creation
    fi
else
    echo "No matching rows found. No output file created."  # inform the user if no matching rows are found
fi

exit 0