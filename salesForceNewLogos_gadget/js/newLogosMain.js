// $(function() {
//         $('#product').hide();
//         console.log("product hide ");
//         $('#category').change(function(){
//             if($('#category').val() == 'overall') {
//                 $('#product').hide();
//                 console.log("product hide ");
//             } else {
//                 $('#product').show(); 
//             } 
//         });
// }); 


// $('#category').on('changed.bs.select', function (e) {
//   if($('#category').val() == 'overall') {
//                 $('#product').hide();
//                 console.log("product hide ");
//             } else {
//                 $('#product').show(); 
//             } 
// });   

  var serviceName = "salesForceCustomerDetailsServices";  
 $.ajax({

            
            url:'https://localhost:9092/'+ serviceName +'/years',
            async:false,
            success: function(data){

              document.getElementById("year1").innerHTML="";
              document.getElementById("year2").innerHTML="";  
              var jsonArrayLength=data[0].length;

              for (i = 0; i < jsonArrayLength; i++) {
                
                   document.getElementById("year1").innerHTML+=" <option value="+data[0][i].Year+">"+data[0][i].Year+"</option>"
                   document.getElementById("year2").innerHTML+=" <option value="+data[0][i].Year+">"+data[0][i].Year+"</option>"
              }
              
            }
          })

var cy = (new Date()).getFullYear()
var y1 =  cy - 1;
var y2 =  cy - 2;

document.getElementById('year1').value=y1;
document.getElementById('year2').value=y2;

console.log(y1);
console.log(y2);

createChart();

$('.changeGraph').change(function(){
        createChart();
});

       
var serviceName = "salesForceCustomerDetailsServices";
function createChart(){
    //alert(event);
    //var ip="10.100.4.2:8280";
    var ip="localhost:9092";
    var year1 = $('#year1').val();
    var year2 = $('#year2').val();
    var type=  $('#type').val();
    var category= $('#category').val();
    var product= $('#product').val();;
    var link="";
    var key="";
    var initialval=0;
    var yAxisLabale="";
    var jsonWonArray=[];
    var jsonLostArray=[];
    // alert(foo);
    // alert(fo);
    //console.log(year);

    // if(category=="overall"){
    //     product="overall";
    // }else{
    //     product=$('#product').val();
    // }

    if(type=="bymonth"){
        //link='http://'+ip+'/api.salesforcecustom/1.0.0/bymonthlogos/'+year1+'/'+year2+'/'+product;
        link='https://'+ip+'/'+ serviceName +'/bymonthlogos/'+year1+'/'+year2+'/'+product;
        key="m";
        xAxisLabale="Month";
        initialval=1;
    }else if(type=="byquater"){
        //link='http://'+ip+'/api.salesforcecustom/1.0.0/byquarterlogos/'+year1+'/'+year2+'/'+product;
        link='https://'+ip+'/'+ serviceName +'/byquarterlogos/'+year1+'/'+year2+'/'+product;
        key="q";
        xAxisLabale="Quater";
        initialval=1;
    }else if(type=="byyear"){
        //link='http://'+ip+'/api.salesforcecustom/1.0.0/byyearlogos/'+year1+'/'+year2+'/'+product;
        link='https://'+ip+'/'+ serviceName +'/byyearlogos/'+year1+'/'+year2+'/'+product;
        key="q";
        key="y";
        xAxisLabale="Year";
        year="";
      
    }else if(type=="byweek"){
        //link='http://'+ip+'/api.salesforcecustom/1.0.0/byweeklogos/'+year1+'/'+year2+'/'+product;
        link='https://'+ip+'/'+ serviceName +'/byweeklogos/'+year1+'/'+year2+'/'+product;
        key="q";
        key="w";
        xAxisLabale="Week";
        initialval=0;
    }



       
   
        var json ={}
        $.ajax({

           
            url:link,
            async:false,
            success: function(data){
              //alert("aaaaaaaaaaa"); 
                  var jsonArrayLength=data[0].length;
                  for (i = 0; i < jsonArrayLength; i++) {
                        
                            jsonWonArray[i]=data[0][i][key];
                            jsonLostArray[i]=data[1][i][key];

                  }
              

              json=data;
              console.log(data);
            }
          })

        Highcharts.chart('container', {
          chart: {
              type: 'column',
              //height: '80%',


          },
          title: {
              text: 'New Logos'
          },
          xAxis: {
                title: {
                    text: xAxisLabale
                }
          },
          yAxis: {
              min: 0,
              title: {
                  text: 'Number of new logos'
              },
              stackLabels: {
                  enabled: true,
                  style: {
                      fontWeight: 'bold',
                      color: (Highcharts.theme && Highcharts.theme.textColor) || 'gray'
                  }
              }
          },
          legend: {
              align: 'right',
              x: -30,
              verticalAlign: 'top',
              y: 25,
              floating: true,
              backgroundColor: (Highcharts.theme && Highcharts.theme.background2) || 'white',
              borderColor: '#CCC',
              borderWidth: 1,
              shadow: false
          },
          tooltip: {
              headerFormat: '<b>{point.x}</b><br/>',
              pointFormat: '{series.name}: {point.y}<br/>Total: {point.stackTotal}'
          },
          plotOptions: {
              column: {
                  //stacking: 'normal',
                  dataLabels: {
                      enabled: true,
                      color: (Highcharts.theme && Highcharts.theme.dataLabelsColor) || 'white'
                  }
              },
              series: {
                        pointStart:1
              }
          },
          series: [{
              name: year1,
              data: jsonWonArray
          }, {
              name: year2,
              data: jsonLostArray
          }]
      
        });


       


        


}
