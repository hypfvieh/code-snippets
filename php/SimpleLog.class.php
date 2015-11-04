<?php
/*
        Simple Logger Class
        (c) Maniac 2012
 
        Version: 0.5
 
        Description:
                Logs Messages to a flatfile
 
        Usage:
                $logger = new simplelog("/tmp/myfile.log");
                $logger->ip = true
                $logger->lineend = "\r\n";
                [...]
 
                # this is the simplest method, just log message as type "INFO"
                $logger->log("my message");
 
                # log message as "ERROR"
                $logger->log(0,"my message");
 
                # log message as WARNING, add filename and line of the sourcemessage
                $logger->log(1,"my message",__FILE__,__LINE__);
 
 
        MessageTypes:
                There are some default message types assigned to the integer values 0-3:
 
                SLOG_ERROR(0), SLOG_WARN(1), SLOG_INFO(2), SLOG_NOTICE(3);
 
                You can also specify new message types by giving an array to $this->messagetypes
 
                e.g.: $this->messagetypes = array ("user1","user2");
 
                If you dont specify an array, your additional message types will be ignored and are NOT available!
 
                To use your message types, you have to set the first parameter to an integer value higher than 3.
                The new message types are simply added to the list of message types (in the order you have given).
 
                So if I want to use message type "user1" from the example above, I have to use number 4 as first parameter.
                If I want to use "user2" I have to choose 5 and so on...
 
                If you choose an element higher than the length of the array (e.g. array has 5 elements and you choose 6),
                you will find the "message type" 'UNKNOWN_MESSAGE_TYPE' in your logfile.
 
                $defaultmessagetype = array ("ERROR","WARNING","INFO","NOTICE")
                $messagetypes = array ("user1","user2");
 
                ==> appended:
                $allmessagetypes = array("ERROR","WARNING","INFO","NOTICE","user1","user2);
 
 
        Options:
                $this->ip               => Log RemoteIP to File (default: false)
                $this->browser          => Log UserAgent to File (default: false)
                $this->logdate          => Log current date in format specified in $this->dateformat (default: true)
                $this->logtime          => Log current time in format specified in $this->timeformat (default: true)
                $this->dateformat       => php date() parameters to format date (default: Y-m-d)
                $this->timeformat       => php data() parameters to format time (default: H:i:s)
                $this->lineend          => line-ending character (default: \n)
                $this->outputformat     => format the of the logfile
 
        Formatting:
                To format a message you have to change the string in $this->outputformat to your needs.
                The following strings are placeholders for the information simplelog adds.
 
                Remember: Even if you specify e.g. ##SLOG_USERAGENT## but you have disabled $this->browser, ##SLOG_USERAGENT## will simply replace with empty string.
                          Also, if you have enabled $this->browser but you didnt add ##SLOG_USERAGENT## to your output string, the useragent will NOT be written to your file!
 
 
                Placeholder                     Value
                --------------------------------------
                ##SLOG_DATE##                   current date formatted with $this->dateformat
                ##SLOG_TIME##                   current time formatted with $this->timeformat
                ##SLOG_MSGTYPE##                Message Type (e.g. ERROR, INFO...)
                ##SLOG_MESSAGE##                the message you want to log
                ##SLOG_FILE##                   file name you have specied as third parameter to the log-function
                ##SLOG_LINE##                   line you have specied as fourth parameter to the log-function
                ##SLOG_REMOTEIP##               remote IP
                ##SLOG_USERAGENT##              User Agent (Browser)
 
                ##SLOG_NEWLINE##                The lineend sign you specified in $this->lineend
 
        License:
                This code is published under WTFPL (http://sam.zoy.org/wtfpl/COPYING)
 
=======================================================================
Changelog:
 
Version                 action  change
0.1                     new     Initial release
0.2                     added   custom format for logstring
0.3                     added   custom message types
0.4                     added   SLOG-Constants
0.5                     fixed   A lot of bugs
 
=======================================================================
 
*/
 
define("SLOG_NOTICE",3);
define("SLOG_INFO",2);
define("SLOG_WARN",1);
define("SLOG_ERROR",0);
 
class simplelog {
 
        private $logfile = "simplelog.log";
        public $ip = false;
        public $browser = false;
        public $logdate = true;
        public $logtime = true;
        public $dateformat = "Y-m-d";
        public $timeformat = "H:i:s";
        public $lineend = "\n";
        private $default_messagetypes = array ('ERROR','WARNING','INFO','NOTICE');
        public $messagetypes = array();
        public $outputformat = "##SLOG_DATE## ##SLOG_TIME## ##SLOG_MSGTYPE##: ##SLOG_MESSAGE####SLOG_NEWLINE##\t\t\tFile: ##SLOG_FILE## --- Line: ##SLOG_LINE####SLOG_NEWLINE##\t\t\tAddr: ##SLOG_REMOTEIP## --- Browser: ##SLOG_USERAGENT####SLOG_NEWLINE##";
 
 
        private $fh = FALSE;
        protected $allmessagetypes = array();
        function __construct($logfile) {
                $this->logfile = $logfile;
                $this->fh = fopen($this->logfile,"a");
        }
        protected function getmessagetypes() {
                $this->allmessagetypes = (is_array($this->messagetypes)) ? array_merge($this->default_messagetypes, $this->messagetypes) : $this->default_messagetypes;
        }
 
        public function log($msgtype = 2 ,$message, $filename = "",$line = -1) {
                if ($this->fh !== FALSE) {
                        $this->getmessagetypes();
                        $completemsg = $this->outputformat;
                        $completemsg = ($this->logdate) ? str_replace("##SLOG_DATE##",date($this->dateformat),$completemsg) : str_replace("##SLOG_DATE##","",$completemsg);
                        $completemsg = ($this->logtime) ? str_replace("##SLOG_TIME##",date($this->timeformat),$completemsg) : str_replace("##SLOG_TIME##","",$completemsg);
 
                        if (count($this->allmessagetypes)-1 >= $msgtype && $msgtype > -1) {
                                $completemsg = str_replace("##SLOG_MSGTYPE##",$this->allmessagetypes[$msgtype],$completemsg);
                        }
                        else {
                                $completemsg = str_replace("##SLOG_MSGTYPE##","UNKNOWN_MESSAGE_TYPE",$completemsg);
                        }
 
                        $completemsg = str_replace("##SLOG_NEWLINE##",$this->lineend,$completemsg);
 
                        $completemsg = ($filename !== "") ? str_replace("##SLOG_FILE##",$filename,$completemsg) : str_replace("##SLOG_FILE##","",$completemsg);
                        $completemsg = ($line > -1) ? str_replace("##SLOG_LINE##",$line,$completemsg) : str_replace("##SLOG_LINE##","",$completemsg);
 
                        $completemsg = ($this->ip) ? str_replace("##SLOG_REMOTEIP##",$_SERVER['REMOTE_ADDR'],$completemsg) : str_replace("##SLOG_REMOTEIP##","",$completemsg);
                        $completemsg = ($this->browser) ? str_replace("##SLOG_USERAGENT##",$_SERVER['HTTP_USER_AGENT'],$completemsg) : str_replace("##SLOG_USERAGENT##","",$completemsg);
 
                        # Replace message as last action, so if there are any SLOG-Placeholders in it, they wont be replaced :P
                        $completemsg = str_replace("##SLOG_MESSAGE##",$message,$completemsg);
 
                        fputs($this->fh,$completemsg);
 
                }
                else {
                        error_log ("You should create the object before you use it!");
                }
 
        }
 
        function __destruct() {
                if ($this->fh !== FALSE) fclose($this->fh);
        }
}
 
?>
