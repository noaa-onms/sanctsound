// append div for tooltip
var tooltip_div = d3.select("body").append("div")
  .attr("class", "tooltip")
  .style("opacity", 0);

// append div for modal
function appendHtml(el, str) {
  var div = document.createElement('div');
  div.innerHTML = str;
  while (div.children.length > 0) {
    el.appendChild(div.children[0]);
  }
}

var modal_html = '<div aria-labelledby="modal-title" class="modal fade bs-example-modal-lg" id="modal" role="dialog" tabindex="-1"><div class="modal-dialog modal-lg" role="document"><div class="modal-content"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button><h4 class="modal-title" id="modal-title">title</h4></div><div class="modal-body"><iframe data-src="" height="100%" width="100%" frameborder="0"></iframe></div><div class="modal-footer"><button class="btn btn-default btn-sm" data-dismiss="modal">Close</button></div></div></div></div>';

lookups_csv = "https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/gviz/tq?tqx=out:csv&sheet=lookups";

appendHtml(document.body, modal_html); // "body" has two more children - h1 and span.

function basename(path) {
     return path.replace(/.*\//, '');
}

// main function to link svg elements to modal popups with data in csv
function link_svg(svg, csv, debug = false, hover_color = 'yellow', width = '100%', height = '100%', modal_id = 'modal') {
  
  var meta;
  
  var toc_header_colors = {
    'Animal':               '#8DC63F80', 
    'Human-made':           '#A8509F80',
    'Physical':             '#F2652280',
    'Soundscape Snapshots': '#D3D3D380' 
  }; // #041f28

  //  var f_child = div.node().appendChild(f.documentElement);
  d3.xml(svg).then((f) => {
    // https://gist.github.com/mbostock/1014829#gistcomment-2692594
  
    //var tip = d3.tip().attr('class', 'd3-tip').html(function(d) { return d; });
    
    var div = d3.select('#svg');
  
    var f_child = div.node().appendChild(f.documentElement);
    
    // get handle to svg
    var h = d3.select(f_child);
    
    // full size
    h.attr('width', width)
     .attr('height', height);
    
    // get meta_csv url from same Google Sheet with tab having "metadata"
    var meta_csv = new URL(csv);
    var meta_params = meta_csv.searchParams;
    meta_params.set('sheet', 'metadata');
    meta_csv.search = meta_params.toString();
    meta_csv = meta_csv.toString();
    if (debug){ 
      console.log('meta_csv: ' + meta_csv);
    }
    // meta_csv = 'https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/gviz/tq?tqx=out%3Acsv&sheet=metadata'
    //meta = d3.csv.parse(meta_csv);
    var meta = [];
    d3.csv(meta_csv).then(function(mdata) {
      console.log("meta mdata");
      console.log(mdata);
      
      mdata.forEach(function(d) {
        meta.push([ +d.variable, +d.value ]);
      });
    });
    console.log('meta' + meta);

    if (debug){ 
      console.log('before data.forEach');
    }
    
    console.log('csv:' + csv);
    d3.csv(csv).then(function(data) {
      
      if (debug){ 
        console.log("data before filter");
        console.log(data);
      }
      
      data = data.filter(function(d){ 
        return basename(d.sanctuary_code).toLowerCase() == basename(svg).slice(0, -4)
          // & d.tab_name == "ICON.svg"
      });
      
      // TODO: if has section column in argument to fxn
      data = data.sort(
        function(a,b) { return d3.ascending(a.sound_category, b.sound_category) ||  d3.ascending(a.modal_title, b.modal_title) });

      if (debug){ 
        console.log("data after filter and sort");
        console.log(data);
      }

      var category_now = null;
      
      // iterate through rows of csv
      data.forEach(function(d) {
        
        d.svg_id     = d.modal_title.toLowerCase().replace(/ & /g, ' ').replace(/\s/g, '-');
        d.modal_link = './modals/' + d.sanctuary_code.toLowerCase() + '_' + d.svg_id + '.html';
        d.sound_category = d.sound_category.trim();
        
        if (debug){ 
          console.log('forEach d.modal_title: '     + d.modal_title);
          console.log('        d.svg_id: '          + d.svg_id);
          console.log('        d.modal_link: '      + d.modal_link);
          console.log('        d.sound_category: '  + d.sound_category);
        }
      
        function handleClick(){
          if (d.not_modal == 'T'){
            window.location = d.modal_link;
          } else {
            
            if (debug){ 
              console.log('  link:' + d.modal_link);
            }
            
            $('#'+ modal_id).find('iframe')
              .prop('src', function(){ return d.modal_link });
            
            $('#'+ modal_id + '-title').html( d.modal_title );
            
            $('#'+ modal_id).on('show.bs.modal', function () {
              $('.modal-content').css('height',$( window ).height()*0.9);
              $('.modal-body').css('height','calc(100% - 65px - 55.33px)');
            });
            
            $('#'+ modal_id).modal();
          }
        }
        function handleMouseOver(){
          if (debug){ 
              console.log('  mouseover():' + d.svg_id);
          }
           
          d3.select('#' + d.svg_id)
            .style("stroke-width", 2)
            .style("stroke", hover_color);
          
          tooltip_div.transition()
            .duration(200)
            .style("opacity", 0.8);
          tooltip_div.html(d.modal_title + "<br/>")
            .style("left", (d3.event.pageX) + "px")
            .style("top", (d3.event.pageY - 28) + "px");
        }
        function handleMouseOverSansTooltip(){
          if (debug){ 
              console.log(' handleMouseOverSansTooltip():' + d.svg_id);
          }
           
          d3.select('#' + d.svg_id)
            .style("stroke-width", 2)
            .style("stroke", hover_color);
          
        }
        function handleMouseOut(){
          if (debug){ 
              console.log('  mouseout():' + d.svg_id);
            }
            
            //d3.select(this)
            d3.select('#' + d.svg_id)
              .style("stroke-width",0);
  
            tooltip_div.transition()
              .duration(500);
            tooltip_div.style("opacity", 0);
        }
        
        h.select('#' + d.svg_id)
          .on("click", handleClick)
          .on('mouseover', handleMouseOver)
          .on('mouseout', handleMouseOut);
          
        // set outline of paths within group to null
        d3.select('#' + d.svg_id).selectAll("path")
            .style("stroke-width", null)
            .style("stroke", null);
          
        // add to bulleted list of svg elements
        list_text = d.modal_title ? d.modal_title : d.svg_id;  // fall back on id if modal_title not set
        
        // if first in section, then add header
        if (d.sound_category != category_now){
          // F26522
          category_list = d3.select("#svg_list").append("li").
            append("xhtml:span").
              //attr("style", "background-color:"+ toc_header_colors[d.sound_category] + ";font-weight:bold;").
              attr("style", "background-color:"+ toc_header_colors[d.sound_category] + ";").
              text(d.sound_category).
            append("ul");
          category_now = d.sound_category;
        }
        category_list.append("li").append("a")
          .text(list_text)
          .on("click", handleClick)
          .on('mouseover', handleMouseOverSansTooltip)
          .on('mouseout', handleMouseOut);

      
      }); // end: data.forEach({
    }) // end: d3.csv().then({
    .catch(function(error){
      // d3.csv() error   
    }); // end: d3.csv()
    
  // turn off questions by default
  d3.select("#text").attr("display", "none");

  }); // d3.xml(svg).then((f) => {

}
