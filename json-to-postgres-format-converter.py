### Purpose of the script ###
#
# When you archive your logs on an archiving server using logstash, each event in the log is converted into a json object
# before being placed in the archive. I archived my daily postgres logs and wanted to run a daily job over postgres logs
# that runs pgbadger over each script. The problem is that pgbadger expects raw postgres logs, not json objects. 
#
# This scripts un-jsons the og file in archive and converts it back to the original format.
#

import json
import codecs
import logging
import os;
from os import listdir;
from datetime import date, timedelta;

yesterday= date.today() - timedelta(1)
path = '/mnt/logs/archive/'+ yesterday.strftime("%Y/%m/%d/")+'database'
directory_list = [os.path.join(path,f) for f in os.listdir(path)]
for directory in directory_list:

        jsonFileName= directory + '/' + 'postgresql.log'
        postgresFileName=  directory + '/postgres.log'
        print "INFO: trimming "+ jsonFileName + " to " + postgresFileName

        try:
                jsonFile = open(jsonFileName, 'r')
        except IOError:
                print "Error opening " + jsonFileName + " for reading."

        try:
                postgresFile = codecs.open(postgresFileName,'w','utf')
        except IOError:
                print "Error opening " + postgresFileName + " for writing."

        error= False;
        for line in jsonFile:
                try :
                        value = json.loads(line)
                except ValueError:
                        print "Error loading json into python map"
                        error = True;
                try :
                        value= value['message']
                except TypeError:
                        print "Not able to type cast"
                        error= True;
                try:
                        postgresFile.write(value+'\n');
                except Exception as e:
                        logging.exception(e)
                        error= True;
        if not error:
                os.remove(jsonFileName);

        postgresFile.close();
        jsonFile.close()
