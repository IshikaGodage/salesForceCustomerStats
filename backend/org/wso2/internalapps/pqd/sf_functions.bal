package org.wso2.internalapps.pqd;

import ballerina.lang.jsons;
import ballerina.utils.logger;
import ballerina.lang.errors;
import ballerina.lang.files;
import ballerina.lang.blobs;
import ballerina.data.sql;
import ballerina.lang.system;
import ballerina.lang.datatables;
import ballerina.net.http;
import ballerina.lang.messages;
import ballerina.lang.time;
import ballerina.lang.strings;


json confJson = getConfData("config.json");
function getConfData (string filePath) (json) {

    files:File configFile = {path: filePath};

    try{
        files:open(configFile, "r");
        logger:debug(filePath + " file found");

    } catch (errors:Error err) {
        logger:error(filePath + " file not found. " + err.msg);
    }

    var content, numberOfBytes = files:read(configFile, 100000);
    logger:debug(filePath + " content read");

    files:close(configFile);
    logger:debug(filePath + " file closed");

    string configString = blobs:toString(content, "utf-8");

    try{
        json configJson = jsons:parse(configString);
        return configJson;

    } catch (errors:Error err) {
        logger:error("JSON syntax error found in "+ filePath + " " + err.msg);
        json configJson = jsons:parse(configString);
    }
    return null;

}

function getDatabaseMap (json configData)(map) {

    string dbIP;
    int dbPort;
    string dbName;
    string dbUsername;
    string dbPassword;
    int poolSize;

    try {
        dbIP = jsons:getString(configData, "$.PQD_JDBC.DB_HOST");
        dbPort = jsons:getInt(configData, "$.PQD_JDBC.DB_PORT");
        dbName = jsons:getString(configData, "$.PQD_JDBC.DB_NAME");
        dbUsername = jsons:getString(configData, "$.PQD_JDBC.DB_USERNAME");
        dbPassword = jsons:getString(configData, "$.PQD_JDBC.DB_PASSWORD");
        poolSize = jsons:getInt(configData, "$.PQD_JDBC.MAXIMUM_POOL_SIZE");

    } catch (errors:Error err) {
        logger:error("Properties not defined in config.json: " + err.msg );
        dbIP = jsons:getString(configData, "$.PQD_JDBC.DB_HOST");
        dbPort = jsons:getInt(configData, "$.PQD_JDBC.DB_PORT");
        dbName = jsons:getString(configData, "$.PQD_JDBC.DB_NAME");
        dbUsername = jsons:getString(configData, "$.PQD_JDBC.DB_USERNAME");
        dbPassword = jsons:getString(configData, "$.PQD_JDBC.DB_PASSWORD");
        poolSize = jsons:getInt(configData, "$.PQD_JDBC.MAXIMUM_POOL_SIZE");

    }


    map propertiesMap={"jdbcUrl":"jdbc:mysql://"+dbIP+":"+dbPort+"/"+dbName, "username":dbUsername, "password":dbPassword, "maximumPoolSize":poolSize};

    return propertiesMap;

}
function createDBConnection()(sql:ClientConnector) {

    map props = getDatabaseMap(confJson);
    sql:ClientConnector sfDB = create sql:ClientConnector(props);
    return sfDB;
}

function getYears1()(json){
    json send = [];

    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params = [];

    datatable dtOpportunityYears = sfDB.select(GET_DISTINCT_OPPOURTUNITY_YEARS, params);
    var opportunityYearsJson, _ = <json>dtOpportunityYears;

    send[0]= opportunityYearsJson;

    sfDB.close();
    return send;
}

function getWonsAndLostsByYearAndArea1 (string product) (json) {

    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params = [];

    string productAreaFormat = "%"+product+"%";
    sql:Parameter productArea = {sqlType:"varchar", value:productAreaFormat};
    params=[productArea];

    json send = [];

    var startyear=0;
    var endyear=0;

    json wons = {won:[]};
    json losts = {lost:[]};
    json years = {year:[]};


    //datatable query1 = sql:ClientConnector.select(sfDB,"SELECT  year(CreatedDate) AS year, count(year(CreatedDate)) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=1 group by year(CreatedDate);", params); //using CreatedDate
    datatable dtWons = sfDB.select(GET_WON_OPPORTUNITIES_BY_YEAR, params);
    var wonsJson, _ = <json>dtWons;

    //datatable query2 = sql:ClientConnector.select(sfDB,"SELECT  year(CreatedDate) AS year, count(year(CreatedDate)) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=0 group by year(CreatedDate);", params); //using CreatedDate
    datatable dtLosts = sfDB.select(GET_LOST_OPPORTUNITIES_BY_YEAR, params);
    var lostsJson, _ = <json>dtLosts;


    var wonsStartYear, _ = (int)wonsJson[0].year;
    var lostsStartYear, _ = (int)lostsJson[0].year;

    if(wonsStartYear <= lostsStartYear) {
        startyear= wonsStartYear;
    }else{
        startyear= lostsStartYear;
    }


    var wonsEndYear, _ = (int)wonsJson[lengthof wonsJson - 1].year;
    var lostsEndYear, _ = (int)lostsJson[lengthof lostsJson - 1].year;


    if(wonsEndYear >= lostsEndYear) {
        endyear= wonsEndYear;
    }else{
        endyear= lostsEndYear;
    }


    int index = 0;
    var startYearIndex = startyear;

    int wonsCount = lengthof wonsJson;
    int wonsIndex = 0;
    int lostsCount = lengthof lostsJson;
    int lostsIndex = 0;


    while(startYearIndex <= endyear) {

        wons.won[index] = 0;
        losts.lost[index] = 0;
        years.year[index] = startYearIndex;

        var currentLoopYear, _ = (int)years.year[index];

        if(wonsIndex < wonsCount) {
            var wonYear, _ = (int)wonsJson[wonsIndex].year;
            if(wonYear == currentLoopYear && wonsIndex < wonsCount) {
                wons.won[index] = wonsJson[wonsIndex].Number_of_Opportunities;
                wonsIndex = wonsIndex + 1;
            }
        }
        if(lostsIndex < lostsCount) {
            var lostYear, _ = (int)lostsJson[lostsIndex].year;
            if(lostYear == currentLoopYear && lostsIndex < lostsCount) {
                losts.lost[index] = lostsJson[lostsIndex].Number_of_Opportunities;
                lostsIndex = lostsIndex + 1;

            }
        }

        index = index + 1;
        startYearIndex = startYearIndex + 1;

    }

    system:println(wons);
    system:println(losts);
    system:println(years);

    send[0]= wons;
    send[1]= losts;
    send[2]= years;

    sfDB.close();
    return send;
}
function getWonsAndLostsByMonthAndArea1 (string product, int year) (json) {
    json send = [];

    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params = [];
    string productAreaFormat = "%"+product+"%";
    sql:Parameter productArea = {sqlType:"varchar", value:productAreaFormat};
    sql:Parameter filterYear = {sqlType:"integer", value:year};
    params=[productArea, filterYear];

    json wons = [{m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}];
    json losts = [{m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}];


    //datatable query1 = sql:ClientConnector.select(sfDB,"SELECT Month(CreatedDate) AS Month,Count(Month(CreatedDate)) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=1  AND year(CreatedDate)= " + year + " GROUP BY Month(CreatedDate);" , params); //using createdDate
    //datatable query1 = sql:ClientConnector.select(sfDB,"SELECT Closed_Month__c AS Month,count(Closed_Month__c) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=1  AND year(CloseDate)="+year+" group by Closed_Month__c;" , params);
    datatable dtWons = sfDB.select(GET_WON_OPPORTUNITIES_BY_MONTH, params);
    var wonsJson, _ = <json>dtWons;

    //datatable query2 = sql:ClientConnector.select(sfDB,"SELECT Month(CreatedDate) AS Month,Count(Month(CreatedDate)) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=0  AND year(CreatedDate)= " + year + " GROUP BY Month(CreatedDate);" , params); //using createdDate
    //datatable query2 = sql:ClientConnector.select(sfDB,"SELECT Closed_Month__c AS Month,count(Closed_Month__c) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=0  AND year(CloseDate)="+year+" group by Closed_Month__c;" , params);
    datatable dtLosts = sfDB.select(GET_LOST_OPPORTUNITIES_BY_MONTH, params);
    var lostsJson, _ = <json>dtLosts;


    var wonsCount = lengthof wonsJson;
    var lostsCount = lengthof lostsJson;
    system:println(wonsCount);
    system:println(lostsCount);
    var wonsIndex = 1;
    var lostsIndex = 1;
    while(wonsIndex <= wonsCount || lostsIndex <= lostsCount) {
        if(wonsIndex <= wonsCount) {
            var wonMonth, _ = (int)wonsJson[wonsIndex - 1].Month;
            wons[wonMonth - 1].m = wonsJson[wonsIndex - 1].Number_of_Opportunities;
            wonsIndex = wonsIndex + 1;
        }

        if(lostsIndex <= lostsCount) {
            var lostMonth, _ = (int)lostsJson[lostsIndex - 1].Month;
            losts[lostMonth - 1].m = lostsJson[lostsIndex - 1].Number_of_Opportunities;
            lostsIndex = lostsIndex + 1;
        }
    }


    send[0]= wons;
    send[1]= losts;

    sfDB.close();
    return send;
}
function getWonsAndLostsByQuarterAndArea1 (string product, int year) (json) {
    json send = [];

    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params = [];
    string productAreaFormat = "%"+product+"%";
    sql:Parameter productArea = {sqlType:"varchar", value:productAreaFormat};
    sql:Parameter filterYear = {sqlType:"integer", value:year};
    params=[productArea, filterYear];

    json wons = [{q:0}, {q:0}, {q:0}, {q:0}];
    json losts = [{q:0}, {q:0}, {q:0}, {q:0}];

    datatable dtWons = sfDB.select(GET_WON_OPPORTUNITIES_BY_QUARTER, params);
    var wonsJson, _ = <json>dtWons;

    datatable dtLosts = sfDB.select(GET_LOST_OPPORTUNITIES_BY_QUARTER, params);
    var lostsJson, _ = <json>dtLosts;

    var quarterIndex = 0;
    while(quarterIndex < 4) {

        if(quarterIndex < lengthof wonsJson) {
            var wonQuarterName, _ = (string)wonsJson[quarterIndex].Quarter;


            if (wonQuarterName == "Q1") {
                wons[quarterIndex].q = wonsJson[quarterIndex].Number_of_Opportunities;
            } else if (wonQuarterName == "Q2") {
                wons[quarterIndex].q = wonsJson[quarterIndex].Number_of_Opportunities;
            } else if (wonQuarterName == "Q3") {
                wons[quarterIndex].q = wonsJson[quarterIndex].Number_of_Opportunities;
            } else if (wonQuarterName == "Q4") {
                wons[quarterIndex].q = wonsJson[quarterIndex].Number_of_Opportunities;
            }
        }

        if(quarterIndex < lengthof lostsJson) {
            var lostsQuarterName, _ = (string)lostsJson[quarterIndex].Quarter;


            if (lostsQuarterName == "Q1") {
                losts[quarterIndex].q = lostsJson[quarterIndex].Number_of_Opportunities;
            } else if (lostsQuarterName == "Q2") {
                losts[quarterIndex].q = lostsJson[quarterIndex].Number_of_Opportunities;
            } else if (lostsQuarterName == "Q3") {
                losts[quarterIndex].q = lostsJson[quarterIndex].Number_of_Opportunities;
            } else if (lostsQuarterName == "Q4") {
                losts[quarterIndex].q = lostsJson[quarterIndex].Number_of_Opportunities;
            }
        }

        quarterIndex = quarterIndex + 1;

    }

    send[0]= wons;
    send[1]= losts;

    sfDB.close();
    return send;
}
function getWonsAndLostsByWeekAndArea (string product, int year) (json) {
    json send = [];

    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params = [];
    string productAreaFormat = "%"+product+"%";
    sql:Parameter productArea = {sqlType:"varchar", value:productAreaFormat};
    sql:Parameter filterYear = {sqlType:"integer", value:year};
    params=[productArea, filterYear];

    json wons = [];
    json losts = [];
    int weeknum=0;
    while(weeknum < 54){
        wons[weeknum] = {"w":0};
        losts[weeknum] = {"w":0};

        weeknum=weeknum+1;
    }

    //datatable query1 = sql:ClientConnector.select(sfDB,"SELECT Month(CreatedDate) AS Month,Count(Month(CreatedDate)) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=1  AND year(CreatedDate)= " + year + " GROUP BY Month(CreatedDate);" , params); //using createdDate
    //datatable query1 = sql:ClientConnector.select(sfDB,"SELECT Closed_Month__c AS Month,count(Closed_Month__c) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=1  AND year(CloseDate)="+year+" group by Closed_Month__c;" , params);
    datatable dtWons = sfDB.select(GET_WON_OPPORTUNITIES_BY_WEEK, params);
    var wonsJson, _ = <json>dtWons;

    //datatable query2 = sql:ClientConnector.select(sfDB,"SELECT Month(CreatedDate) AS Month,Count(Month(CreatedDate)) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=0  AND year(CreatedDate)= " + year + " GROUP BY Month(CreatedDate);" , params); //using createdDate
    //datatable query2 = sql:ClientConnector.select(sfDB,"SELECT Closed_Month__c AS Month,count(Closed_Month__c) AS Number_of_Opportunities FROM UnifiedDashboards.SF_OPPORTUNITY Where Entry_Vector__c Like '%"+product+"%' AND IsClosed=1 AND IsWon=0  AND year(CloseDate)="+year+" group by Closed_Month__c;" , params);
    datatable dtLosts = sfDB.select(GET_LOST_OPPORTUNITIES_BY_WEEK, params);
    var lostsJson, _ = <json>dtLosts;

    var wonsCount = lengthof wonsJson;
    var lostsCount = lengthof lostsJson;
    system:println(wonsCount);
    system:println(lostsCount);
    var wonsIndex = 0;
    var lostsIndex = 0;
    while(wonsIndex < wonsCount || lostsIndex < lostsCount) {
        if(wonsIndex < wonsCount) {
            var wonWeek, _ = (int)wonsJson[wonsIndex].Week;

            wons[wonWeek].w = wonsJson[wonsIndex].Number_of_Opportunities;

            wonsIndex = wonsIndex + 1;
        }

        if(lostsIndex < lostsCount) {
            var lostWeek, _ = (int)lostsJson[lostsIndex].Week;

            losts[lostWeek].w = lostsJson[lostsIndex].Number_of_Opportunities;

            lostsIndex = lostsIndex + 1;
        }


    }

    system:println(wons);
    system:println(losts);


    send[0]= wons;
    send[1]= losts;

    sfDB.close();
    return send;
}

function getActiveCustomers1(string customerProductArea) (json) {
    sql:ClientConnector sfDB = createDBConnection();
    datatable dtActiveCustomers;
    if (customerProductArea == "All") {
        sql:Parameter[] params = [];
        dtActiveCustomers = sfDB.select(GET_ALL_ACTIVE_CUSTOMERS, params);
    } else {

        sql:Parameter[] params1 = [];
        sql:Parameter productArea = {sqlType:"varchar", value:customerProductArea};
        params1 = [productArea];
        dtActiveCustomers = sfDB.select(GET_ACTIVE_CUSTOMERS_BY_PRODUCT_AREA, params1);
    }

    var activeCustomers, _ = <json>dtActiveCustomers;
    logger:debug(activeCustomers);
    datatables:close(dtActiveCustomers);

    sfDB.close();
    return activeCustomers;
}

function getNewLogosByYearAndArea1 (int year1, int year2, string product) (json) {
    json send = [];

    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params1 = [];
    sql:Parameter[] params2 = [];
    sql:Parameter[] params3 = [];
    sql:Parameter[] params4 = [];


    sql:Parameter filterYear1 = {sqlType:"integer", value:year1};
    sql:Parameter filterYear2 = {sqlType:"integer", value:year2};
    params1=[filterYear1];
    params2=[filterYear2];

    if(product=="IoT"){
        product="Mobile/IoT";
    }else if(product=="APIManagement"){
        product="API Management (true OAuth)";
    }

    json newLogosYear1 = [{y:0}];
    json newLogosYear2 = [{y:0}];

    datatable dtNewLogosYear1 = {};
    datatable dtNewLogosYear2 = {};

    if(product=="overall"){
        dtNewLogosYear1 = sfDB.select(GET_ALL_NEW_LOGOS_BY_YEAR, params1);
        dtNewLogosYear2 = sfDB.select(GET_ALL_NEW_LOGOS_BY_YEAR, params2);
    }else{
        if(product=="Other"){

            product="'Integration','Mobile/IoT','API Management (true OAuth)','Security','Analytics'";
            sql:Parameter productArea1 = {sqlType:"varchar", value:product};
            params3=[productArea1,filterYear1];
            params4=[productArea1,filterYear2];

            dtNewLogosYear1 = sfDB.select(GET_OTHER_NEW_LOGOS_BY_YEAR, params3);
            dtNewLogosYear2 = sfDB.select(GET_OTHER_NEW_LOGOS_BY_YEAR, params4);
        }else{

            sql:Parameter productArea2 = {sqlType:"varchar", value:product};
            params3=[productArea2,filterYear1];
            params4=[productArea2,filterYear2];

            dtNewLogosYear1 = sfDB.select(GET_NEW_LOGOS_BY__AREA_AND_YEAR, params3);
            dtNewLogosYear2 = sfDB.select(GET_NEW_LOGOS_BY__AREA_AND_YEAR, params4);
        }
    }

    var logosYear1, _ = <json>dtNewLogosYear1;
    var logosYear2, _ = <json>dtNewLogosYear2;


    newLogosYear1[0].y = logosYear1[0].NewLogos;
    newLogosYear2[0].y = logosYear2[0].NewLogos;


    send[0]= newLogosYear1;
    send[1]= newLogosYear2;

    sfDB.close();
    system:println(send);
    return send;
}
function getNewLogosByQuarterAndArea1 (int year1, int year2, string product) (json) {
    json send = [];


    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params1 = [];
    sql:Parameter[] params2 = [];
    sql:Parameter[] params3 = [];
    sql:Parameter[] params4 = [];


    sql:Parameter filterYear1 = {sqlType:"integer", value:year1};
    sql:Parameter filterYear2 = {sqlType:"integer", value:year2};
    params1=[filterYear1];
    params2=[filterYear2];

    if(product=="IoT"){
        product="Mobile/IoT";
    }else if(product=="APIManagement"){
        product="API Management (true OAuth)";
    }

    json newLogosYear1 = [{q:0}, {q:0}, {q:0}, {q:0}];
    json newLogosYear2 = [{q:0}, {q:0}, {q:0}, {q:0}];

    datatable dtNewLogosYear1 = {};
    datatable dtNewLogosYear2 = {};



    if(product=="overall"){
        dtNewLogosYear1 = sfDB.select(GET_ALL_NEW_LOGOS_BY_YEAR_AND_QUARTER, params1);
        dtNewLogosYear2 = sfDB.select(GET_ALL_NEW_LOGOS_BY_YEAR_AND_QUARTER, params2);
    }else{
        if(product=="Other"){
            product="'Integration','Mobile/IoT','API Management (true OAuth)','Security','Analytics'";

            sql:Parameter productArea1 = {sqlType:"varchar", value:product};
            params3=[productArea1,filterYear1];
            params4=[productArea1,filterYear2];

            dtNewLogosYear1 = sfDB.select(GET_OTHER_NEW_LOGOS_BY_YEAR_AND_QUARTER, params3);
            dtNewLogosYear2 = sfDB.select(GET_OTHER_NEW_LOGOS_BY_YEAR_AND_QUARTER, params4);
        }else{

            sql:Parameter productArea1 = {sqlType:"varchar", value:product};
            params3=[productArea1,filterYear1];
            params4=[productArea1,filterYear2];

            dtNewLogosYear1 = sfDB.select(GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_QUATER, params3);
            dtNewLogosYear2 = sfDB.select(GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_QUATER, params4);
        }
    }

    var logosYear1, _ = <json>dtNewLogosYear1;
    var logosYear2, _ = <json>dtNewLogosYear2;

    var quarterIndex = 0;
    while(quarterIndex < 4) {



        if(quarterIndex < lengthof logosYear1) {
            var quarterNameYear1, _ = (int)logosYear1[quarterIndex].Quarter;


            if (quarterNameYear1 == 1) {
                newLogosYear1[quarterIndex].q = logosYear1[quarterIndex].NewLogos;
            } else if (quarterNameYear1 == 2) {
                newLogosYear1[quarterIndex].q = logosYear1[quarterIndex].NewLogos;
            } else if (quarterNameYear1 == 3) {
                newLogosYear1[quarterIndex].q = logosYear1[quarterIndex].NewLogos;
            } else if (quarterNameYear1 == 4) {
                newLogosYear1[quarterIndex].q = logosYear1[quarterIndex].NewLogos;
            }
        }

        if(quarterIndex < lengthof logosYear2) {
            var quarterNameYear2, _ = (int)logosYear2[quarterIndex].Quarter;


            if (quarterNameYear2 == 1) {
                newLogosYear2[quarterIndex].q = logosYear2[quarterIndex].NewLogos;
            } else if (quarterNameYear2 == 2) {
                newLogosYear2[quarterIndex].q = logosYear2[quarterIndex].NewLogos;
            } else if (quarterNameYear2 == 3) {
                newLogosYear2[quarterIndex].q = logosYear2[quarterIndex].NewLogos;
            } else if (quarterNameYear2 == 4) {
                newLogosYear2[quarterIndex].q = logosYear2[quarterIndex].NewLogos;
            }
        }

        quarterIndex = quarterIndex + 1;
    }

    send[0]= newLogosYear1;
    send[1]= newLogosYear2;

    sfDB.close();

    return send;
}
function getNewLogosByMonthAndArea1 (int year1, int year2, string product) (json) {
    json send = [];

    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params1 = [];
    sql:Parameter[] params2 = [];
    sql:Parameter[] params3 = [];
    sql:Parameter[] params4 = [];


    sql:Parameter filterYear1 = {sqlType:"integer", value:year1};
    sql:Parameter filterYear2 = {sqlType:"integer", value:year2};
    params1=[filterYear1];
    params2=[filterYear2];

    if(product=="IoT"){
        product="Mobile/IoT";
    }else if(product=="APIManagement"){
        product="API Management (true OAuth)";
    }

    json newLogosYear1 = [{m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}];
    json newLogosYear2 = [{m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}];

    datatable dtNewLogosYear1 = {};
    datatable dtNewLogosYear2 = {};

    if(product=="overall"){
        dtNewLogosYear1 = sfDB.select(GET_ALL_NEW_LOGOS_BY_YEAR_AND_MONTH, params1);
        dtNewLogosYear2 = sfDB.select(GET_ALL_NEW_LOGOS_BY_YEAR_AND_MONTH, params2);
    }else{
        if(product=="Other"){
            product="'Integration','Mobile/IoT','API Management (true OAuth)','Security','Analytics'";

            sql:Parameter productArea1 = {sqlType:"varchar", value:product};
            params3=[productArea1,filterYear1];
            params4=[productArea1,filterYear2];

            dtNewLogosYear1 = sfDB.select(GET_OTHER_NEW_LOGOS_BY_YEAR_AND_MONTH, params3);
            dtNewLogosYear2 = sfDB.select(GET_OTHER_NEW_LOGOS_BY_YEAR_AND_MONTH, params4);
        }else{

            sql:Parameter productArea1 = {sqlType:"varchar", value:product};
            params3=[productArea1,filterYear1];
            params4=[productArea1,filterYear2];

            dtNewLogosYear1 = sfDB.select(GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_MONTH, params3);
            dtNewLogosYear2 = sfDB.select(GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_MONTH, params4);
        }
    }

    var logosYear1, _ = <json>dtNewLogosYear1;
    var logosYear2, _ = <json>dtNewLogosYear2;
    system:print(logosYear1);

    var logosCountYear1 = lengthof logosYear1;
    var logosCountYear2 = lengthof logosYear2;
    system:println(logosCountYear1);
    system:println(logosCountYear2);
    var logosIndexYear1 = 1;
    var logosIndexYear2 = 1;
    while(logosIndexYear1 <= logosCountYear1 || logosIndexYear2 <= logosCountYear2) {
        if(logosIndexYear1 <= logosCountYear1) {
            var logoMonthYear1, _ = (int)logosYear1[logosIndexYear1 - 1].Month;
            system:println(logoMonthYear1);
            newLogosYear1[logoMonthYear1 - 1].m = logosYear1[logosIndexYear1 - 1].NewLogos;
            logosIndexYear1 = logosIndexYear1 + 1;
        }

        if(logosIndexYear2 <= logosCountYear2) {
            var logoMonthYear2, _ = (int)logosYear2[logosIndexYear2 - 1].Month;
            system:println(logoMonthYear2);
            newLogosYear2[logoMonthYear2 - 1].m = logosYear2[logosIndexYear2 - 1].NewLogos;
            logosIndexYear2 = logosIndexYear2 + 1;
        }
    }


    send[0]= newLogosYear1;
    send[1]= newLogosYear2;

    sfDB.close();

    return send;
}
function getNewLogosByWeekAndArea (int year1, int year2, string product) (json) {
    json send = [];

    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params1 = [];
    sql:Parameter[] params2 = [];
    sql:Parameter[] params3 = [];
    sql:Parameter[] params4 = [];


    sql:Parameter filterYear1 = {sqlType:"integer", value:year1};
    sql:Parameter filterYear2 = {sqlType:"integer", value:year2};
    params1=[filterYear1];
    params2=[filterYear2];

    if(product=="IoT"){
        product="Mobile/IoT";
    }else if(product=="APIManagement"){
        product="API Management (true OAuth)";
    }

    json newLogosYear1 = [];
    json newLogosYear2 = [];
    int weeknum=0;
    while(weeknum < 54){
        newLogosYear1[weeknum] = {"w":0};
        newLogosYear2[weeknum] = {"w":0};

        weeknum=weeknum+1;
    }

    datatable dtNewLogosYear1 = {};
    datatable dtNewLogosYear2 = {};

    if(product=="overall"){
        dtNewLogosYear1 = sfDB.select(GET_ALL_NEW_LOGOS_BY_YEAR_AND_WEEK, params1);
        dtNewLogosYear2 = sfDB.select(GET_ALL_NEW_LOGOS_BY_YEAR_AND_WEEK, params2);
    }else{
        if(product=="Other"){
            product="'Integration','Mobile/IoT','API Management (true OAuth)','Security','Analytics'";

            sql:Parameter productArea1 = {sqlType:"varchar", value:product};
            params3=[productArea1,filterYear1];
            params4=[productArea1,filterYear2];

            dtNewLogosYear1 = sfDB.select(GET_OTHER_NEW_LOGOS_BY_YEAR_AND_WEEK, params3);
            dtNewLogosYear2 = sfDB.select(GET_OTHER_NEW_LOGOS_BY_YEAR_AND_WEEK, params4);
        }else{

            sql:Parameter productArea1 = {sqlType:"varchar", value:product};
            params3=[productArea1,filterYear1];
            params4=[productArea1,filterYear2];

            dtNewLogosYear1 = sfDB.select(GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_WEEK, params3);
            dtNewLogosYear2 = sfDB.select(GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_WEEK, params4);
        }
    }


    var logosYear1, _ = <json>dtNewLogosYear1;
    var logosYear2, _ = <json>dtNewLogosYear2;

    var logosCountYear1 = lengthof logosYear1;
    var logosCountYear2 = lengthof logosYear2;

    var logosIndexYear1 = 0;
    var logosIndexYear2 = 0;
    while(logosIndexYear1 < logosCountYear1 || logosIndexYear2 < logosCountYear2) {
        if(logosIndexYear1 < logosCountYear1) {
            var logoWeekYear1, _ = (int)logosYear1[logosIndexYear1].Week;

            newLogosYear1[logoWeekYear1].w = logosYear1[logosIndexYear1].NewLogos;

            logosIndexYear1 = logosIndexYear1 + 1;
        }

        if(logosIndexYear2 < logosCountYear2) {
            var logoWeekYear2, _ = (int)logosYear2[logosIndexYear2].Week;

            newLogosYear2[logoWeekYear2].w = logosYear2[logosIndexYear2].NewLogos;

            logosIndexYear2 = logosIndexYear2 + 1;
        }

    }
    send[0]= newLogosYear1;
    send[1]= newLogosYear2;

    sfDB.close();

    return send;
}

function getDetailsLogs5(string date1, string date2, string product)(json){
    sql:ClientConnector sfDB = createDBConnection();
    sql:Parameter[] params = [];

    if(product=="IoT"){
        product="Mobile/IoT";
    }else if(product=="APIManagement"){
        product="API Management (true OAuth)";
    }

    json queryresult1send=[{m:0},{m:0},{m:0},{m:0},{m:0},{m:0},{m:0},{m:0},{m:0},{m:0},{m:0},{m:0}];


    datatable query1={};


    if(product=="overall"){
        query1 = sfDB.select("SELECT Month(Activation_Date__c) AS Month,count(Month(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and Activation_Date__c BETWEEN '"+date1+"'   AND '"+date2+"' group by Month(Activation_Date__c);", params);
        system:print("date2");

    }else{
        if(product=="Other"){
            product="('Integration','Mobile/IoT','API Management (true OAuth)','Security','Analytics')";
            //query1 = sql:ClientConnector.select(sfDB,"SELECT Month(Activation_Date__c) AS Month,count(Month(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c not in "+product+" and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)="+year1+" group by Month(Activation_Date__c);" , params);

        }else{
            //query1 = sql:ClientConnector.select(sfDB,"SELECT Month(Activation_Date__c) AS Month,count(Month(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c in ('"+product+"') and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)="+year1+" group by Month(Activation_Date__c);" , params);

        }
    }

    var queryresult1, _=<json>query1;


    system:print(queryresult1);
    var l= lengthof queryresult1;

    system:println(l);

    var i=1;
    var a=1;
    while(i<=l){
        if(i<=l){
            var j, _=(int)queryresult1[i-1].Month;
            system:println(j);
            queryresult1send[j-1].m= queryresult1[i-1].NewLogos;
            i = i+1;
        }


    }

    sfDB.close();

    return queryresult1send;
}






function getActiveCustomers()(json){

    time:Time t = time:currentTime();
    string currentDate = time:format(t,"YYYY-MM-dd");
    system:println(currentDate);
    system:println("function in");
    message request = {};
    message response = {};
    json projectJson = {};
    messages:setHeader(request,"Authorization","");
    http:ClientConnector Conn = create http:ClientConnector("http://localhost:8080/service/sf");
    //response = Conn.get("/getOppourtunityAndOppLineItemDetails?productUnit="+customerProductArea+"&PSSupportAccountEndDateRollUpDate="+currentDate+"&PSSupportAccountEndDateRollUpDateOperator=gte&oppoLineItemTotalPrice=DESC&orderByCustomerId=true&oppoLineItemTotalPrice=DESC", request);
    response = Conn.get("/getAccountAndOppourtunityAndOppLineItemDetails?accountStatus=Customer&PSSupportAccountEndDateRollUpDate="+currentDate+"&PSSupportAccountEndDateRollUpDateOperator=gt&orderByCustomerId=true&orderByOppourtunityId=true",request);
    projectJson = messages:getJsonPayload(response);
    system:println(projectJson);
    system:println(lengthof projectJson);


    json nameAndArrJson= [];

    int accountIndex =0;
    while(accountIndex< lengthof projectJson ){
        if(projectJson[accountIndex].Oppourtunities != null){


            json jsonObject = {};
            var integrationArr = 0;
            var iamArr= 0;
            var apimArr = 0;
            var analyticsArr = 0;
            var iotArr = 0;
            var otherArr =0;
            var allArr = 0;

            int oppourtunityIndex = 0;
            while(oppourtunityIndex< lengthof projectJson[accountIndex].Oppourtunities){

                if(projectJson[accountIndex].Oppourtunities[oppourtunityIndex].OpportunityLineItems != null){


                    var integrationCount = 0;
                    var iamCount = 0;
                    var apimCount = 0;
                    var analyticsCount = 0;
                    var iotCount = 0;
                    var otherCount = 0;
                    int oppourtunityLineItemIndex = 0;

                    //system:println(projectJson[accountIndex].Oppourtunities[oppourtunityIndex].OpportunityLineItems);

                    while(oppourtunityLineItemIndex< lengthof projectJson[accountIndex].Oppourtunities[oppourtunityIndex].OpportunityLineItems){

                        //system:println(projectJson[accountIndex].Oppourtunities[oppourtunityIndex].OpportunityLineItems[oppourtunityLineItemIndex]);
                        var productArea, _ = (string)projectJson[accountIndex].Oppourtunities[oppourtunityIndex].OpportunityLineItems[oppourtunityLineItemIndex].Product_Unit__c;

                        if( productArea == "Integration"){
                            integrationCount = integrationCount+1;
                        }

                        if(productArea == "IAM"){
                            iamCount = iamCount+1;
                        }


                        if(productArea == "APIM"){
                            apimCount = apimCount+1;
                        }


                        if(productArea == "Analytics"){
                            analyticsCount = analyticsCount+1;
                        }

                        if(productArea == "IOT"){
                            iotCount = iotCount+1;
                        }


                        if(productArea == "Other"){
                            otherCount = otherCount+1;
                        }


                        oppourtunityLineItemIndex = oppourtunityLineItemIndex +1;
                    }

                    var arrString, _ =(string)projectJson[accountIndex].Oppourtunities[oppourtunityIndex].ARR_Opportunity__c;
                    var arrArray = strings:split(arrString,"\\.");
                    var arr, _ = <int>arrArray[0];


                    integrationArr = integrationArr + (arr * integrationCount);
                    iamArr = iamArr + (arr * iamCount) ;
                    apimArr =  apimArr + (arr * apimCount) ;
                    analyticsArr = analyticsArr + (arr * analyticsCount);
                    iotArr = iotArr + (arr * iotCount);
                    otherArr = otherArr + (arr * otherCount);




                }


                oppourtunityIndex = oppourtunityIndex +1;
            }
            allArr = (integrationArr+iamArr+apimArr+analyticsArr+iotArr+otherArr);
            jsonObject.Name = projectJson[accountIndex].Name;
            jsonObject.integrationArr = integrationArr;
            jsonObject.iamArr = iamArr;
            jsonObject.apimArr = apimArr;
            jsonObject.analyticsArr = analyticsArr;
            jsonObject.iotArr = iotArr;
            jsonObject.otherArr = otherArr;
            jsonObject.allArr = allArr;
            nameAndArrJson[accountIndex] = jsonObject;

        }

        accountIndex = accountIndex + 1;
    }


    return nameAndArrJson;
}

function getNewLogosByMonthAndArea(string area,string year1,string year2)(json){
    json send=[];
    json newLogosYear1 = [{m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}];
    json newLogosYear2 = [{m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}];

    message request = {};
    message response1 = {};
    message response2 = {};
    json projectJson1 = {};
    json projectJson2 = {};
    messages:setHeader(request,"Authorization","");
    http:ClientConnector Conn = create http:ClientConnector("http://localhost:8080/service/sf");
    if(area == "overall"){
        response1 = Conn.get("/getAccountDetails?newLogosByYear="+year1+"&orderByActivationDate=ASC", request);
        response2 = Conn.get("/getAccountDetails?newLogosByYear="+year2+"&orderByActivationDate=ASC", request);
    }else{
        response1 = Conn.get("/getAccountDetails?entryVector="+area+"&newLogosByYear="+year1+"&orderByActivationDate=ASC", request);
        response2 = Conn.get("/getAccountDetails?entryVector="+area+"&newLogosByYear="+year2+"&orderByActivationDate=ASC", request);
    }

    projectJson1 = messages:getJsonPayload(response1);
    projectJson2 = messages:getJsonPayload(response2);

    int i=0;
    var memMonth=0;
    var count = 0;
    while(i<lengthof projectJson1){

        var date, _ = (string)projectJson1[i].Activation_Date__c;
        string monthString = strings:subString(date,5,7);
        var month, _ = <int>monthString;

        if(memMonth == 0) {
            count = 1;
        }else if(memMonth != month && memMonth != 0){
            newLogosYear1[memMonth-1].m=count;
            count = 1;
        }else{
            count = count +1;
        }


        memMonth = month;

        system:println(month);
        system:println(date);


        i=i+1;
        if(i==lengthof projectJson1){
            newLogosYear1[memMonth-1].m=count;
            count=0;
            memMonth=0;
        }
    }


    int j=0;
    while(j<lengthof projectJson2){

        var date, _ = (string)projectJson2[j].Activation_Date__c;
        string monthString = strings:subString(date,5,7);
        var month, _ = <int>monthString;

        if(memMonth == 0) {
            count = 1;
        }else if(memMonth != month && memMonth != 0){
            newLogosYear2[memMonth-1].m=count;
            count = 1;
        }else{
            count = count +1;
        }


        memMonth = month;

        system:println(month);
        system:println(date);


        j=j+1;
        if(j==lengthof projectJson2){
            newLogosYear2[memMonth-1].m=count;
        }
    }
    system:println(newLogosYear1);
    system:println(newLogosYear2);
    system:println(projectJson1);
    system:println(projectJson2);

    send[0]=newLogosYear1;
    send[1]=newLogosYear2;

    return send;
}
function getNewLogosByQuarterAndArea(string area,string year1,string year2)(json){
    json send=[];
    json newLogosYear1 = [{q:0}, {q:0}, {q:0}, {q:0}];
    json newLogosYear2 = [{q:0}, {q:0}, {q:0}, {q:0}];

    message request = {};
    message response1 = {};
    message response2 = {};
    json projectJson1 = {};
    json projectJson2 = {};
    messages:setHeader(request,"Authorization","");
    http:ClientConnector Conn = create http:ClientConnector("http://localhost:8080/service/sf");
    if(area == "overall"){
        response1 = Conn.get("/getAccountDetails?newLogosByYear="+year1+"&orderByActivationDate=ASC", request);
        response2 = Conn.get("/getAccountDetails?newLogosByYear="+year2+"&orderByActivationDate=ASC", request);
    }else{
        response1 = Conn.get("/getAccountDetails?entryVector="+area+"&newLogosByYear="+year1+"&orderByActivationDate=ASC", request);
        response2 = Conn.get("/getAccountDetails?entryVector="+area+"&newLogosByYear="+year2+"&orderByActivationDate=ASC", request);
    }

    projectJson1 = messages:getJsonPayload(response1);
    projectJson2 = messages:getJsonPayload(response2);

    int i=0;
    var memQuarter=0;
    var count = 0;
    while(i<lengthof projectJson1){

        var date, _ = (string)projectJson1[i].Activation_Date__c;
        string monthString = strings:subString(date,5,7);
        var month, _ = <int>monthString;

        var quarter=0;

        if (month <= 3) {
            quarter = 1;
        } else if (month <= 6) {
            quarter = 2;
        } else if (month <= 9) {
            quarter = 3;
        } else {
            quarter = 4;
        }

        if(memQuarter == 0) {
            count = 1;
        }else if(memQuarter != quarter && memQuarter != 0){
            newLogosYear1[memQuarter-1].q=count;
            count = 1;
        }else{
            count = count +1;
        }


        memQuarter = quarter;

        system:println(quarter);
        system:println(date);


        i=i+1;
        if(i==lengthof projectJson1){
            newLogosYear1[memQuarter-1].q=count;
            count=0;
            memQuarter=0;
        }
    }


    int j=0;
    while(j<lengthof projectJson2){

        var date, _ = (string)projectJson2[j].Activation_Date__c;
        string monthString = strings:subString(date,5,7);
        var month, _ = <int>monthString;

        var quarter=0;
        if (month <= 3) {
            quarter = 1;
        } else if (month <= 6) {
            quarter = 2;
        } else if (month <= 9) {
            quarter = 3;
        } else {
            quarter = 4;
        }


        if(memQuarter == 0) {
            count = 1;
        }else if(memQuarter != quarter && memQuarter != 0){
            newLogosYear2[memQuarter-1].q=count;
            count = 1;
        }else{
            count = count +1;
        }


        memQuarter = quarter;

        system:println(quarter);
        system:println(date);


        j=j+1;
        if(j==lengthof projectJson2){
            newLogosYear2[memQuarter-1].q=count;
            count=0;
            memQuarter=0;
        }
    }
    system:println(newLogosYear1);
    system:println(newLogosYear2);
    system:println(projectJson1);
    system:println(projectJson2);

    send[0]=newLogosYear1;
    send[1]=newLogosYear2;

    return send;
}
function getNewLogosByYearAndArea(string area,string year1,string year2)(json){

    json send=[];
    message request = {};
    message response1 = {};
    message response2 = {};
    json projectJson1 = {};
    json projectJson2 = {};
    json json1=[{"y":0}];
    json json2=[{"y":0}];
    messages:setHeader(request,"Authorization","");
    http:ClientConnector Conn = create http:ClientConnector("http://localhost:8080/service/sf");
    if(area == "overall"){
        response1 = Conn.get("/getAccountDetails?newLogosByYear="+year1+"&orderByActivationDate=ASC", request);
        response2 = Conn.get("/getAccountDetails?newLogosByYear="+year2+"&orderByActivationDate=ASC", request);
    }else{
        response1 = Conn.get("/getAccountDetails?entryVector="+area+"&newLogosByYear="+year1+"&orderByActivationDate=ASC", request);
        response2 = Conn.get("/getAccountDetails?entryVector="+area+"&newLogosByYear="+year2+"&orderByActivationDate=ASC", request);
    }
    projectJson1 = messages:getJsonPayload(response1);
    projectJson2 = messages:getJsonPayload(response2);
    system:println("year1: " + lengthof projectJson1);
    system:println("year2: " + lengthof projectJson2);

    json1[0].y=lengthof projectJson1;
    json2[0].y=lengthof projectJson2;

    send[0]=json1;
    send[1]=json2;
    return send;
}

function getWonsAndLostsByMonthAndArea (string area, string year)(json){

    //if(area=="OpenBanking"){
    //    area = "Open Banking";
    //}

    json send=[];
    json won = [{m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}];
    json lost = [{m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}, {m:0}];

    message request = {};
    message response1 = {};
    message response2 = {};
    json projectJson1 = {};
    json projectJson2 = {};
    messages:setHeader(request,"Authorization","");
    http:ClientConnector Conn = create http:ClientConnector("http://localhost:8080/service/sf");
    response1 = Conn.get("/getOppourtunityDetails?entryVector="+area+"&isClosed=true&isWon=true&closeDateYear="+year+"&orderByClosedDate=ASC", request);
    response2 = Conn.get("/getOppourtunityDetails?entryVector="+area+"&isClosed=true&isWon=false&closeDateYear="+year+"&orderByClosedDate=ASC", request);
    projectJson1 = messages:getJsonPayload(response1);
    projectJson2 = messages:getJsonPayload(response2);


    int i=0;
    var memMonth=0;
    var count = 0;
    while(i<lengthof projectJson1){

        var date, _ = (string)projectJson1[i].CloseDate;
        string monthString = strings:subString(date,5,7);
        var month, _ = <int>monthString;

        if(memMonth == 0) {
            count = 1;
        }else if(memMonth != month && memMonth != 0){
            won[memMonth - 1].m = count;
            count = 1;
        }else{
            count = count +1;
        }


        memMonth = month;

        system:println(month);
        system:println(date);


        i=i+1;
        if(i==lengthof projectJson1){
            won[memMonth - 1].m = count;
            count=0;
            memMonth=0;
        }
    }


    int j=0;
    while(j<lengthof projectJson2){

        var date, _ = (string)projectJson2[j].CloseDate;
        string monthString = strings:subString(date,5,7);
        var month, _ = <int>monthString;

        if(memMonth == 0) {
            count = 1;
        }else if(memMonth != month && memMonth != 0){
            lost[memMonth - 1].m = count;
            count = 1;
        }else{
            count = count +1;
        }


        memMonth = month;

        system:println(month);
        system:println(date);


        j=j+1;
        if(i==lengthof projectJson1){
            lost[memMonth - 1].m = count;
        }
    }
    system:println(won);
    system:println(lost);
    system:println(projectJson1);
    system:println(projectJson2);

    send[0]= won;
    send[1]= lost;

    return send;
}
function getWonsAndLostsByQuarterAndArea (string area, string year)(json){
    json send=[];
    json won = [{q:0}, {q:0}, {q:0}, {q:0}];
    json lost = [{q:0}, {q:0}, {q:0}, {q:0}];

    message request = {};
    message response1 = {};
    message response2 = {};
    json projectJson1 = {};
    json projectJson2 = {};
    messages:setHeader(request,"Authorization","");
    http:ClientConnector Conn = create http:ClientConnector("http://localhost:8080/service/sf");
    response1 = Conn.get("/getOppourtunityDetails?entryVector="+area+"&isClosed=true&isWon=true&closeDateYear="+year+"&orderByClosedDate=ASC", request);
    response2 = Conn.get("/getOppourtunityDetails?entryVector="+area+"&isClosed=true&isWon=false&closeDateYear="+year+"&orderByClosedDate=ASC", request);
    projectJson1 = messages:getJsonPayload(response1);
    projectJson2 = messages:getJsonPayload(response2);

    int i=0;
    var memQuarter=0;
    var count = 0;
    while(i<lengthof projectJson1){

        var date, _ = (string)projectJson1[i].CloseDate;
        string monthString = strings:subString(date,5,7);
        var month, _ = <int>monthString;

        var quarter=0;

        if (month <= 3) {
            quarter = 1;
        } else if (month <= 6) {
            quarter = 2;
        } else if (month <= 9) {
            quarter = 3;
        } else {
            quarter = 4;
        }

        if(memQuarter == 0) {
            count = 1;
        }else if(memQuarter != quarter && memQuarter != 0){
            won[memQuarter - 1].q = count;
            count = 1;
        }else{
            count = count +1;
        }


        memQuarter = quarter;

        system:println(quarter);
        system:println(date);


        i=i+1;
        if(i==lengthof projectJson1){
            won[memQuarter - 1].q = count;
            count=0;
            memQuarter=0;
        }
    }


    int j=0;
    while(j<lengthof projectJson2){

        var date, _ = (string)projectJson2[j].CloseDate;
        string monthString = strings:subString(date,5,7);
        var month, _ = <int>monthString;

        var quarter=0;
        if (month <= 3) {
            quarter = 1;
        } else if (month <= 6) {
            quarter = 2;
        } else if (month <= 9) {
            quarter = 3;
        } else {
            quarter = 4;
        }


        if(memQuarter == 0) {
            count = 1;
        }else if(memQuarter != quarter && memQuarter != 0){
            lost[memQuarter - 1].q = count;
            count = 1;
        }else{
            count = count +1;
        }


        memQuarter = quarter;

        system:println(quarter);
        system:println(date);


        j=j+1;
        if(j==lengthof projectJson2){
            lost[memQuarter - 1].q = count;
            count=0;
            memQuarter=0;
        }
    }
    system:println(won);
    system:println(lost);
    system:println(projectJson1);
    system:println(projectJson2);

    send[0]= won;
    send[1]= lost;

    return send;
}
function getWonsAndLostsByYearAndArea (string area)(json){
    json send=[];

    var startyear=0;
    var endyear=0;

    json wons = {won:[]};
    json losts = {lost:[]};
    json years = {year:[]};

    json wonsJson = [];
    json lostsJson = [];

    message request = {};
    message response1 = {};
    message response2 = {};
    json projectJson1 = {};
    json projectJson2 = {};
    messages:setHeader(request,"Authorization","");
    http:ClientConnector Conn = create http:ClientConnector("http://localhost:8080/service/sf");
    response1 = Conn.get("/getOppourtunityDetails?entryVector="+area+"&isClosed=true&isWon=true&orderByClosedDate=ASC", request);
    response2 = Conn.get("/getOppourtunityDetails?entryVector="+area+"&isClosed=true&isWon=false&orderByClosedDate=ASC", request);
    projectJson1 = messages:getJsonPayload(response1);
    projectJson2 = messages:getJsonPayload(response2);


    int wonYearMem=0;
    var wonCount = 0;
    int wonIndex=0;
    int i=0;
    while(i<lengthof projectJson1){
        json won={year:0,Number_of_Opportunities:0};
        var date, _ = (string)projectJson1[i].CloseDate;
        string yearString = strings:subString(date,0,4);
        var year, _ = <int>yearString;


        if(wonYearMem == 0) {
            wonCount = 1;
        }else if(wonYearMem != year && wonYearMem != 0){

            won.year=wonYearMem;
            won.Number_of_Opportunities=wonCount;
            wonsJson[wonIndex]=won;
            wonIndex =wonIndex+1;
            wonCount = 1;
        }else{
            wonCount = wonCount +1;
        }

        wonYearMem = year;
        i=i+1;
        if(i==lengthof projectJson1){
            won.year=wonYearMem;
            won.Number_of_Opportunities=wonCount;
            wonsJson[wonIndex]=won;

        }

    }

    int lostYearMem=0;
    var lostCount = 0;
    int lostIndex=0;
    int j=0;
    while(j<lengthof projectJson2){
        json lost={year:0,Number_of_Opportunities:0};
        var date, _ = (string)projectJson2[j].CloseDate;
        string yearString = strings:subString(date,0,4);
        var year, _ = <int>yearString;

        if(lostYearMem == 0) {
            lostCount = 1;
        }else if(lostYearMem != year && lostYearMem != 0){

            lost.year=lostYearMem;
            lost.Number_of_Opportunities=lostCount;
            lostsJson[lostIndex]=lost;
            lostIndex =lostIndex+1;
            lostCount = 1;
        }else{
            lostCount = lostCount +1;
        }

        lostYearMem = year;
        j=j+1;
        if(j==lengthof projectJson2){
            lost.year=lostYearMem;
            lost.Number_of_Opportunities=lostCount;
            lostsJson[lostIndex]=lost;

        }

    }

    system:println(wonsJson);
    system:println(lostsJson);

    var wonsStartYear, _ = (int)wonsJson[0].year;
    var lostsStartYear, _ = (int)lostsJson[0].year;

    if(wonsStartYear <= lostsStartYear) {
        startyear= wonsStartYear;
    }else{
        startyear= lostsStartYear;
    }


    var wonsEndYear, _ = (int)wonsJson[lengthof wonsJson - 1].year;
    var lostsEndYear, _ = (int)lostsJson[lengthof lostsJson - 1].year;


    if(wonsEndYear >= lostsEndYear) {
        endyear= wonsEndYear;
    }else{
        endyear= lostsEndYear;
    }


    int index = 0;
    var startYearIndex = startyear;

    int wonsCount = lengthof wonsJson;
    int wonsIndex = 0;
    int lostsCount = lengthof lostsJson;
    int lostsIndex = 0;


    while(startYearIndex <= endyear) {

        wons.won[index] = 0;
        losts.lost[index] = 0;
        years.year[index] = startYearIndex;

        var currentLoopYear, _ = (int)years.year[index];

        if(wonsIndex < wonsCount) {
            var wonYear, _ = (int)wonsJson[wonsIndex].year;
            if(wonYear == currentLoopYear && wonsIndex < wonsCount) {
                wons.won[index] = wonsJson[wonsIndex].Number_of_Opportunities;
                wonsIndex = wonsIndex + 1;
            }
        }
        if(lostsIndex < lostsCount) {
            var lostYear, _ = (int)lostsJson[lostsIndex].year;
            if(lostYear == currentLoopYear && lostsIndex < lostsCount) {
                losts.lost[index] = lostsJson[lostsIndex].Number_of_Opportunities;
                lostsIndex = lostsIndex + 1;

            }
        }

        index = index + 1;
        startYearIndex = startYearIndex + 1;

    }

    system:println(wons);
    system:println(losts);
    system:println(years);

    send[0]= wons;
    send[1]= losts;
    send[2]= years;

    return send;
}

function getYears()(json){
    json send = [];
    message request = {};
    message response1 = {};

    json projectJson1 = {};

    json yearsJson = [];

    messages:setHeader(request,"Authorization","");
    http:ClientConnector Conn = create http:ClientConnector("http://localhost:8080/service/sf");
    response1 = Conn.get("/getOppourtunityDetails?&isClosed=true&orderByClosedDate=ASC", request);

    projectJson1 = messages:getJsonPayload(response1);

    int yearMem = 0;

    int yearsIndex = 0;
    int i=0;
    while(i<lengthof projectJson1){
        json yearObject = {};
        var date, _ = (string)projectJson1[i].CloseDate;
        string yearString = strings:subString(date,0,4);
        var year, _ = <int>yearString;


        if(yearMem == 0) {

        }else if(yearMem != year && yearMem != 0) {

            yearObject.Year = yearMem;

            yearsJson[yearsIndex] = yearObject;
            yearsIndex = yearsIndex + 1;

        }else{

        }

        yearMem = year;
        i=i+1;
        if(i==lengthof projectJson1){
            yearObject.Year = yearMem;

            yearsJson[yearsIndex] = yearObject;

        }

    }

    system:println(yearsJson);


    send[0]= yearsJson;
    return send;

}





