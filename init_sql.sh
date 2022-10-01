# init_sql

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Initialize PG."
   echo
   echo "Syntax: bash init_sql.sh [options]"
   echo "options:"
   echo "h     Print this Help."
   echo "u     Specify the PG Username to connect with."
   echo "p     Specify the PG Passwod to connect with."
   echo "t     OPTIONAL Specify the table name to create (if not exists)."
   echo "d     OPTIONAL Specify the database name to create (if not exists)."
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Get the options
while getopts ":ht:d:u:p:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      t) # get table
         TABLE=${OPTARG}
         ;;
      d) # get database
         DB_NAME=${OPTARG}
         ;;
      u) # get PG user
         PG_USER=${OPTARG}
         ;;
      p) # get PG password
         PG_PASSWORD=${OPTARG}
         ;;
   esac
done

# Assign default values if options not supplied
if [ -z ${TABLE+x} ]; then
    TABLE="diag";
fi

# Assign log dir if not supplied
if [ -z ${DB_NAME+x} ]; then
    DB_NAME="av_streaming";
fi

# Set PG envvar for password
export PGPASSWORD=$PG_PASSWORD

# Create the database if it doesn't exist
psql -U $PG_USER -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || psql -U $PG_USER -c "CREATE DATABASE $DB_NAME"

# Create the table within the database if it doesn't exist
SCHEMA="(id serial PRIMARY KEY, timestamp float, vin char(17), make varchar(20), model varchar(20), position_x float, position_y float, position_z float, speed float)"
CREATE_TBL_CMD="CREATE TABLE IF NOT EXISTS $TABLE $SCHEMA;"
psql -U $PG_USER -d $DB_NAME -c "$CREATE_TBL_CMD"

# Verify the table exists and output the message
CHECK="SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='$TABLE')"
result=`psql -U $PG_USER -d $DB_NAME -Axqtc "$CHECK"`
exists=`echo "$result" | cut -d"|" -f2`

if [ "$exists" == "t" ]; then
    echo "Success: Table $TABLE created.";
    exit 0;
else
    echo "Failure: Table $TABLE doesn't exist.";
    exit 1;
fi
