
#include "settings.h"
#include "util.h"

void Settings::loadSettings(){
    
    rtd_server_prog_id    = Util::getINIString("RTDServerProgID");     
    bar_period            = Util::getINIInt   ("BarPeriod");
    csv_path              = Util::getINIString("CSVFolderPath"); 
    bell_wait_time        = Util::getINIInt   ("BellWaitTime"); 
    ab_db_path            = Util::getINIString("AbDbPath");     
    no_of_scrips          = 0 ;    

    std::string scrip_value;
    std::string scrip_key;

    if( bar_period < 1000  ){                                                // check $TICKMODE 1
        throw "Minimum Bar Interval is 1000ms";        
    }
        
    Util::createDirectory( csv_path );                                   // If folder does not exist, create it.
    csv_path.append("quotes.rtd");
    
    while(1){
        scrip_key    = "Scrip";  scrip_key.append( std::to_string( (long long)no_of_scrips+1 ) );
        scrip_value  = Util::getINIString( scrip_key.c_str() ) ;

        if(scrip_value.empty()){                                             // No more Scrips left
            if( no_of_scrips == 0 ){
                throw( "Atleast one scrip needed" );
            }
            else break;
        }

        //  ScripID(mandatory);Alias(mandatory);LTP(mandatory);LTT;Todays Volume;OI;LTP Multiplier  
        std::vector<std::string>  split_strings;
        Util::splitString( scrip_value , ';', split_strings ) ;
        if(split_strings.size() < 3 ){                                       // 3 mandatory field at start
            throw( scrip_key + " Invalid" ); 
        }

        Scrip    scrip_topics;

        scrip_topics.topic_name   =  split_strings[0];     
        scrip_topics.ticker       =  split_strings[1];
        scrip_topics.topic_LTP    =  split_strings[2];

        if(split_strings.size() >=4 ){
            scrip_topics.topic_LTT       =  split_strings[3];
        }
        if(split_strings.size() >=5 ){
            scrip_topics.topic_vol_today =  split_strings[4];
        }
        if(split_strings.size() >=6 ){
            scrip_topics.topic_OI        =  split_strings[5];
        } 
        if(split_strings.size() >=7 && !split_strings[6].empty() ){ 
            scrip_topics.ltp_multiplier  =  std::stoi( split_strings[6] );
        }
        else {
            scrip_topics.ltp_multiplier  =  1;
        }

        scrips_array.push_back(  scrip_topics ) ;
        no_of_scrips++;
    } 
}

