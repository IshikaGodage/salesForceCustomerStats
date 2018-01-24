package org.wso2.internalapps.pqd;

const string GET_DISTINCT_OPPOURTUNITY_YEARS="SELECT DISTINCT(YEAR(closeDate)) AS  Year
                                              FROM SF_OPPORTUNITY
                                              where IsClosed=1
                                              ORDER BY YEAR(CloseDate) ASC;";

const string GET_WON_OPPORTUNITIES_BY_YEAR = "SELECT  year(CloseDate) AS year, count(year(CloseDate)) AS Number_of_Opportunities
                                              FROM SF_OPPORTUNITY
                                              Where Entry_Vector__c Like ? AND
                                              IsClosed=1 AND
                                              IsWon=1
                                              group by year(CloseDate) ASC;";

const string GET_LOST_OPPORTUNITIES_BY_YEAR = "SELECT  year(CloseDate) AS year, count(year(CloseDate)) AS Number_of_Opportunities
                                               FROM SF_OPPORTUNITY
                                               Where Entry_Vector__c Like ? AND
                                               IsClosed=1 AND
                                               IsWon=0
                                               group by year(CloseDate) ASC;";

const string GET_WON_OPPORTUNITIES_BY_MONTH= "SELECT Month(CloseDate) AS Month,Count(Month(CloseDate)) AS Number_of_Opportunities
                                              FROM SF_OPPORTUNITY
                                              Where Entry_Vector__c Like ? AND
                                              IsClosed=1 AND IsWon=1  AND
                                              year(CloseDate)= ?
                                              GROUP BY Month(CloseDate);";

const string GET_LOST_OPPORTUNITIES_BY_MONTH= "SELECT Month(CloseDate) AS Month,Count(Month(CloseDate)) AS Number_of_Opportunities
                                               FROM SF_OPPORTUNITY
                                               Where Entry_Vector__c Like ? AND
                                               IsClosed=1 AND IsWon=0  AND
                                               year(CloseDate)= ?
                                               GROUP BY Month(CloseDate);";

const string GET_WON_OPPORTUNITIES_BY_QUARTER= "SELECT Closed_QTR__c AS Quarter,count(Closed_QTR__c) AS Number_of_Opportunities
                                              FROM SF_OPPORTUNITY
                                              Where Entry_Vector__c Like ? AND
                                              IsClosed=1 AND IsWon=1  AND
                                              year(CloseDate)=?
                                              GROUP BY Closed_QTR__c;";

const string GET_LOST_OPPORTUNITIES_BY_QUARTER= "SELECT Closed_QTR__c AS Quarter,count(Closed_QTR__c) AS Number_of_Opportunities
                                                 FROM SF_OPPORTUNITY
                                                 Where Entry_Vector__c Like ? AND
                                                 IsClosed=1 AND IsWon=0  AND
                                                 year(CloseDate)=?
                                                 GROUP BY Closed_QTR__c;";

const string GET_WON_OPPORTUNITIES_BY_WEEK= "SELECT WEEK(CloseDate) AS Week,Count(WEEK(CloseDate)) AS Number_of_Opportunities
                                             FROM SF_OPPORTUNITY
                                             Where Entry_Vector__c Like ? AND
                                             IsClosed=1 AND IsWon=1  AND
                                             year(CloseDate)=?
                                             GROUP BY WEEK(CloseDate);";

const string GET_LOST_OPPORTUNITIES_BY_WEEK= "SELECT WEEK(CloseDate) AS Week,Count(WEEK(CloseDate)) AS Number_of_Opportunities
                                              FROM SF_OPPORTUNITY
                                              Where Entry_Vector__c Like ? AND
                                              IsClosed=1 AND IsWon=0  AND
                                              year(CloseDate)=?
                                              GROUP BY WEEK(CloseDate);";

const string GET_ALL_ACTIVE_CUSTOMERS="select sum(total) as totalAmount, Name, Product from (SELECT sum(o.Amount) as total , a.Name as Name ,m.ProductArea as Product  from SF_OPPORTUNITY o
                                       join SF_OPPOLINEITEM l on l.OpportunityId = o.Id
                                       join SF_ACCOUNT a on a.Id = o.AccountId
                                       join SF_PRODUCT_TO_ENTRY_VECTOR_MAP m on m.EntryVector = o.Entry_Vector__c
                                       where o.PS_Support_Account_End_Date_Roll_Up__c >= current_date() and
                                             o.PS_Support_Account_Start_Date_Roll_Up__c <= current_date() and
                                             (l.Classification__c = 'PS' or l.Classification__c = 'LI') and
                                             o.Entry_Vector__c != ' NULL'
									   Group by o.Amount, a.Name, o.Entry_Vector__c, m.EntryVector
                                       order by o.Amount DESC) as x group by Name,Product
                                       order by totalAmount DESC;";

const string GET_ACTIVE_CUSTOMERS_BY_PRODUCT_AREA= "select sum(total) as totalAmount, Name, Product from (SELECT sum(o.Amount) as total , a.Name as Name ,m.ProductArea as Product  from SF_OPPORTUNITY o
                                       join SF_OPPOLINEITEM l on l.OpportunityId = o.Id
                                       join SF_ACCOUNT a on a.Id = o.AccountId
                                       join SF_PRODUCT_TO_ENTRY_VECTOR_MAP m on m.EntryVector = o.Entry_Vector__c
                                       where o.PS_Support_Account_End_Date_Roll_Up__c >= current_date() and
                                             o.PS_Support_Account_Start_Date_Roll_Up__c <= current_date() and
                                             (l.Classification__c = 'PS' or l.Classification__c = 'LI') and
                                             o.Entry_Vector__c != ' NULL' and
                                             m.ProductArea=?
									   Group by o.Amount, a.Name, o.Entry_Vector__c, m.EntryVector
                                       order by o.Amount DESC) as x group by Name,Product
                                       order by totalAmount DESC;";

const string final = "SELECT sum(l.TotalPrice), a.Name from SF_OPPORTUNITY o
                                       join SF_OPPOLINEITEM l on l.OpportunityId = o.Id
                                       join SF_ACCOUNT a on a.Id = o.AccountId
                                       where o.PS_Support_Account_End_Date_Roll_Up__c >= current_date()
									   AND a.Account_Status__c ='Customer'
                                       AND l.Product_Unit__c = 'IAM'
                                       group by a.Name
                                       order by a.Name ;";

const string GET_ALL_NEW_LOGOS_BY_YEAR= "SELECT count(*) AS NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in('Public Cloud') and year(Activation_Date__c)=?;";
const string GET_OTHER_NEW_LOGOS_BY_YEAR= "SELECT count(*) AS NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c not in (?) and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in('Public Cloud') and year(Activation_Date__c)=?;";
const string GET_NEW_LOGOS_BY__AREA_AND_YEAR= "SELECT count(*) AS NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c in (?) and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in('Public Cloud') and year(Activation_Date__c)=?;";


const string GET_ALL_NEW_LOGOS_BY_YEAR_AND_QUARTER= "SELECT quarter(Activation_Date__c) AS Quarter,count(quarter(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by quarter(Activation_Date__c);";
const string GET_OTHER_NEW_LOGOS_BY_YEAR_AND_QUARTER= "SELECT quarter(Activation_Date__c) AS Quarter,count(quarter(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c not in (?) and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by quarter(Activation_Date__c);";
const string GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_QUATER= "SELECT quarter(Activation_Date__c) AS Quarter,count(quarter(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c in (?) and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by quarter(Activation_Date__c);";


const string GET_ALL_NEW_LOGOS_BY_YEAR_AND_MONTH= "SELECT Month(Activation_Date__c) AS Month,count(Month(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by Month(Activation_Date__c);";
const string GET_OTHER_NEW_LOGOS_BY_YEAR_AND_MONTH= "SELECT Month(Activation_Date__c) AS Month,count(Month(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c not in (?) and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by Month(Activation_Date__c);";
const string GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_MONTH= "SELECT Month(Activation_Date__c) AS Month,count(Month(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c in (?) and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by Month(Activation_Date__c);";


const string GET_ALL_NEW_LOGOS_BY_YEAR_AND_WEEK= "SELECT Week(Activation_Date__c) AS Week,count(Week(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by Week(Activation_Date__c);";
const string GET_OTHER_NEW_LOGOS_BY_YEAR_AND_WEEK= "SELECT Week(Activation_Date__c) AS Week,count(Week(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c not in (?) and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by Week(Activation_Date__c);";
const string GET_NEW_LOGOS_BY__AREA_AND_YEAR_AND_WEEK= "SELECT Week(Activation_Date__c) AS Week,count(Week(Activation_Date__c)) NewLogos FROM UnifiedDashboards.SF_ACCOUNT where Entry_Vector_Roll_up__c in (?) and Account_Classification__c not in ('3rd Party / Other','Partner',' NULL') and Sub_Category__c not in ('Public Cloud') and year(Activation_Date__c)=? group by Week(Activation_Date__c);";
