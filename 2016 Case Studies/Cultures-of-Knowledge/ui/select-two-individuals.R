
tabPanel("Select Two Individuals",
         wellPanel(HTML(
           paste(
             "<h1>Proof of Concept</h1>",
             "<p>This is a proof of concept for selecting an individual and seeing their connections.</p>",
             "<p>The following features are provided:</p>",
             "<ul>",
             "<li>Select a name from the drop down menu (note additional fields may be added)</li>",
             "<li>The individuals person details are displayed beneath</li>",
             "<li>The network below includes only those individuals connected to the selected individual</li>",
             "<li>Hovering over nodes displays the individual's name</li>",
             "</ul>",
             "<p>Please note no effort has been made to catch errors and while loading error messages
             may show - this can be fixed with minimal effort.</p>",
             "<p><em>Note:</em> It would be possible to modify this screen to allow n-degree neighbours of the selected
             individual to be displayed, this would require ~1 hour development time</p>",
             sep = ""
           )
         )),
         fluidRow(
           column(uiOutput("select.individual.1_UI"),width=4),
           column(uiOutput("select.individual.2_UI"),width=4),
           column(uiOutput("select.individual.3_UI"),width=4)),
         fluidRow(
           column(uiOutput("selected.individual.network_no_graph"),
                  visNetworkOutput("select.individual.network_graph",width = "100%"),width = 9),
           column(uiOutput("visNetwork_selected_individual_show_timeslider_UI"), 
                  uiOutput("visNetwork_selected_individual_time_period_of_interest_UI"),
                  uiOutput("neighbor.degree.UI"),width = 3)
         )
         )