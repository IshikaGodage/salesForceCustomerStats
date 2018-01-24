package org.wso2.internalapps.pqd;

import ballerina.net.http;
import ballerina.lang.messages;

import ballerina.utils.logger;

@http:configuration {basePath:"/salesForceCustomerDetailsServices",httpsPort: 9092, keyStoreFile: "${ballerina.home}/bre/security/wso2carbon.jks", keyStorePass: "wso2carbon", certPass: "wso2carbon"}
service<http> Service1 {

    @http:Path {value:"/years"}

    resource getYears (message m){
        // This resource for get the distinct years of the database  which  has opportunities.
        message response = {};
        json send = [];
        send = getYears();
        logger:info("/years Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }

    @http:Path {value:"/byyear/{productArea}"}

    resource getWonsAndLostsByYearAndArea(message m,@http:PathParam {value:"productArea"} string productArea){
        message response = {};
        json send = [];
        send = getWonsAndLostsByYearAndArea(productArea);
        logger:info("/byyear/{productArea} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }

    @http:Path {value:"/bymonth/{product}/{year}"}

    resource getWonsAndLostsByMonthAndArea (message m,@http:PathParam {value:"product"} string product,@http:PathParam {value:"year"} string year){
        message response = {};
        json send = [];
        send = getWonsAndLostsByMonthAndArea(product, year);
        logger:info("/bymonth/{product}/{year} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }


    @http:Path {value:"/byquarter/{product}/{year}"}

    resource getWonsAndLostsByQuarterAndArea (message m,@http:PathParam {value:"product"} string product,@http:PathParam {value:"year"} string year){
        message response = {};
        json send = [];
        send = getWonsAndLostsByQuarterAndArea(product, year);
        logger:info("/byquarter/{product}/{year} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }


    @http:Path {value:"/byweek/{product}/{year}"}

    resource getWonsAndLostsByWeekAndArea (message m,@http:PathParam {value:"product"} string product,@http:PathParam {value:"year"} int year){
        message response = {};
        json send =[];
        send = getWonsAndLostsByWeekAndArea(product, year);
        logger:info("/byweek/{product}/{year} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }


    @http:Path {value:"/customer/{product}"}
    resource getActiveCustomers (message m,@http:PathParam {value:"product"} string product){

        message response = {};
        json send = [];
        //send=getActiveCustomers1(product);
        send=getActiveCustomers();
        logger:info("/customer/{product} Rest call triggered");
        messages:setJsonPayload(response, send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;

    }


    @http:Path {value:"/byyearlogos/{year1}/{year2}/{product}"}

    resource getNewLogosByYearAndArea (message m,@http:PathParam {value:"year1"} string year1,@http:PathParam {value:"year2"} string year2,@http:PathParam {value:"product"} string product){
        message response = {};
        json send = [];
        send = getNewLogosByYearAndArea(product, year1, year2);
        logger:info("/byyearlogos/{year1}/{year2}/{product} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }


    @http:Path {value:"/byquarterlogos/{year1}/{year2}/{product}"}

    resource getNewLogosByQuarterAndArea (message m,@http:PathParam {value:"year1"} string year1,@http:PathParam {value:"year2"} string year2,@http:PathParam {value:"product"} string product){
        message response = {};
        json send = [];
        send = getNewLogosByQuarterAndArea(product, year1, year2);
        logger:info("/byquarterlogos/{year1}/{year2}/{product} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }


    @http:Path {value:"/bymonthlogos/{year1}/{year2}/{product}"}

    resource getNewLogosByMonthAndArea (message m,@http:PathParam {value:"year1"} string year1,@http:PathParam {value:"year2"} string year2,@http:PathParam {value:"product"} string product){
        message response = {};
        json send = [];
        send = getNewLogosByMonthAndArea(product, year1, year2);
        logger:info("/bymonthlogos/{year1}/{year2}/{product} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }


    @http:Path {value:"/byweeklogos/{year1}/{year2}/{product}"}

    resource getNewLogosByWeekAndArea (message m,@http:PathParam {value:"year1"} int year1,@http:PathParam {value:"year2"} int year2,@http:PathParam {value:"product"} string product){
        message response = {};
        json send = [];
        send = getNewLogosByWeekAndArea(year1, year2, product);
        logger:info("/byweeklogos/{year1}/{year2}/{product} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }


    @http:Path {value:"/bymonthlogosdaterange/{date1}/{date2}/{product}"}

    resource resource12 (message m,@http:PathParam {value:"date1"} string date1,@http:PathParam {value:"date2"} string date2,@http:PathParam {value:"product"} string product){
        message response = {};
        json send = [];
        send = getDetailsLogs5(date1, date2, product);
        logger:info("/bymonthlogosdaterange/{date1}/{date2}/{product} Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }

    @http:Path {value:"/test/{product}/{year1}/{year2}"}

    resource resource13 (message m,@http:PathParam {value:"product"} string product,@http:PathParam {value:"year1"} string year1,@http:PathParam {value:"year2"} string year2){
        message response = {};
        json send = [];
        //send = newlogosbyyear(product,year1, year2);
        //send = newlogosbymonth(product,year1, year2);
        //send = newlogosbyquarter(product,year1, year2);

        logger:info("/test Rest call triggered");
        messages:setJsonPayload(response,send);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }


}
