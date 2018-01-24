var serviceName = "salesForceCustomerDetailsServices"; 
   $.ajax({

            //url:"http://10.100.4.2:8280/api.salesforcecustom/1.0.0/years",
            // beforeSend: function( xhr ) {
            //   xhr.setRequestHeader('Accept', 'application/json');
            //   xhr.setRequestHeader('Authorization', 'Bearer 32d7d9db-ec69-36e8-b273-447a621a9edc');
            // },
            url:'https://localhost:9092/'+ serviceName +'/years',
            async:false,
            success: function(data){
              document.getElementById("year").innerHTML="";  
              var jsonArrayLength=data[0].length;

              for (i = 0; i < jsonArrayLength; i++) {
                
                   document.getElementById("year").innerHTML+=" <option value="+data[0][i].Year+">"+data[0][i].Year+"</option>"
              }
              
            }
    })

   //$('#year').hide();
var cy = (new Date()).getFullYear()
var y1 =  cy - 1;
document.getElementById('year').value=y1;
createChart();



$('#type').change(function(){
      if($('#type').val() == 'byyear') {
          $('#year').hide(); 
          // f();
      } else {
          $('#year').show(); 
          // f();
      } 
      
      
});



// $('#product').change(function(){
//       f();
//       console.log("test1");
// });

// $('#year').change(function(){
//       f();
//       console.log("test2");
// });

$('.changeGraph').change(function(){
      createChart();
});

var serviceName = "salesForceCustomerDetailsServices";
function createChart(){
        //alert(event);
        //var ip="10.100.4.2:8280";
        var ip="localhost:9092";
        var year = $('#year').val();
        var product = $('#product').val();
        var type=  $('#type').val();
        var link="";
        var key="";
        var initialval=0;
        var yAxisLabale="";
        var jsonWonArray=[];
        var jsonLostArray=[];
        // alert(foo);
        // alert(fo);
        //console.log(year);

        if(type=="bymonth"){
            //link='http://'+ip+'/api.salesforcecustom/1.0.0/bymonth/'+product+'/'+year;
            link='https://'+ip+'/'+ serviceName +'/bymonth/'+product+'/'+year;
            key="m";
            xAxisLabale="Month";
            initialval=0;
            categories=['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        }else if(type=="byquarter"){
            //link='http://'+ip+'/api.salesforcecustom/1.0.0/byquater/'+product+'/'+year;
            link='https://'+ip+'/'+ serviceName +'/byquarter/'+product+'/'+year;
            key="q";
            xAxisLabale="Quarter";
            initialval=0;
            categories=['Q1','Q2','Q3','Q4'];
        }else if(type=="byyear"){
            //link='http://'+ip+'/api.salesforcecustom/1.0.0/byyear/'+product;
            link='https://'+ip+'/'+ serviceName +'/byyear/'+product;
            key="y";
            xAxisLabale="Year";
            year="";
            $("#year").hide();
            categories=[];

        }else if(type=="byweek"){
            //link='http://'+ip+'/api.salesforcecustom/1.0.0/byweek/'+product+'/'+year;
            link='https://'+ip+'/'+ serviceName +'/byweek/'+product+'/'+year;
            key="w";
            xAxisLabale="Week";
            initialval=1;
            categories=[];
            
        }



 
        var json ={}
        $.ajax({

            // url:link,
            // beforeSend: function( xhr ) {
            //   xhr.setRequestHeader('Accept', 'application/json');
            //   xhr.setRequestHeader('Authorization', 'Bearer 32d7d9db-ec69-36e8-b273-447a621a9edc');
            // },
            url:link,
            async:false,
            success: function(data){
              //alert("aaaaaaaaaaa"); 
              if(type=="byyear"){
                    jsonWonArray=data[0].won;
                    jsonLostArray=data[1].lost;
                    initialval=data[2].year[0];
              }else{
                  var jsonArrayLength=data[0].length;
                  for (i = 0; i < jsonArrayLength; i++) {
                        
                            jsonWonArray[i]=data[0][i][key];
                            jsonLostArray[i]=data[1][i][key];

                  }
              }

              json=data;
              console.log(jsonWonArray);
            }
        });


        Highcharts.chart('containerTrendChart', {

                title: {
                    text: year
                },

                subtitle: {
                    text: 'Wons/Losts'
                },

                yAxis: {
                    title: {
                        text: 'Number of Opportunities'
                    }
                },
                xAxis: {
                    categories:categories,
                    title: {
                        text: xAxisLabale
                    }
                },
                // legend: {
                //     layout: 'vertical',
                //     align: 'right',
                //     verticalAlign: 'middle'
                // },

                plotOptions: {
                    series: {
                        pointStart:initialval
                    }
                },

                series: [{
                    name: 'WON',
                    data: jsonWonArray

                },
                {
                    name: 'LOST',
                    data: jsonLostArray
                }]

              });   


        


}
