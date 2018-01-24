var serviceName = "salesForceCustomerDetailsServices"; 
   $.ajax({

            
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

   $('#year').hide();
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
            initialval=1;
        }else if(type=="byquarter"){
            //link='http://'+ip+'/api.salesforcecustom/1.0.0/byquater/'+product+'/'+year;
            link='https://'+ip+'/'+ serviceName +'/byquarter/'+product+'/'+year;
            key="q";
            xAxisLabale="Quarter";
            initialval=1;
        }else if(type=="byyear"){
            //link='http://'+ip+'/api.salesforcecustom/1.0.0/byyear/'+product;
            link='https://'+ip+'/'+ serviceName +'/byyear/'+product;
            key="y";
            xAxisLabale="Year";
            year="";
            $("#year").hide();

        }else if(type=="byweek"){
            //link='http://'+ip+'/api.salesforcecustom/1.0.0/byweek/'+product+'/'+year;
            link='https://'+ip+'/'+ serviceName +'/byweek/'+product+'/'+year;
            key="w";
            xAxisLabale="Week";
            initialval=0;
            
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


        Highcharts.chart('containerColumnChart', {
                chart: {
                    type: 'column'
                },
                title: {
                    text: year
                },
                subtitle: {
                    text: 'Wons/Losts'
                },
                yAxis: {
                    min: 0,
                    title: {
                        text: 'Number of Opportunities'
                    }
                },
                xAxis: {
                        title: {
                            text: xAxisLabale
                        }
                },
                tooltip: {
                    headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
                    pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' +
                        '<td style="padding:0"><b>{point.y:.1f}</b></td></tr>',
                    footerFormat: '</table>',
                    shared: true,
                    useHTML: true
                },
                plotOptions: {
                    column: {
                        pointPadding: 0.2,
                        borderWidth: 0,
                        dataLabels: {
                              enabled: true,
                              color: (Highcharts.theme && Highcharts.theme.dataLabelsColor) || 'Black'
                        }

                    },
                    series: {
                                pointStart:initialval
                            }
                },
                series: [{
                    name: 'Won',
                    data: jsonWonArray

                }, 
                {
                    name: 'Lost',
                    data: jsonLostArray

                }]
        });


}
