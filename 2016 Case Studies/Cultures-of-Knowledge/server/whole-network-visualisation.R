## =============================== License ========================================
## ================================================================================
## This work is distributed under the MIT license, included in the parent directory
## Copyright Owner: University of Oxford
## Date of Authorship: 2016
## Author: Martin John Hadley (orcid.org/0000-0002-3039-6849)
## Academic Contact: Arno Bosse (http://orcid.org/0000-0003-3681-1289)
## Data Source: emlo.bodleian.ox.ac.uk
## ================================================================================

## ================================================================================
## ===================== Whole Network Visualisation ==============================


### ====================================== UI Elements =====================================
### ========================================================================================


output$visNetwork_wholeNetwork_show_timeslider_UI <- renderUI({
  checkboxInput("visNetwork_wholeNetwork_show_timeslider", label = "Remove undated interactions and filter by date?", value = TRUE)
})

output$visNetwork_wholeNetwork_time_period_of_interest_UI <-
  renderUI({
    if (is.null(input$visNetwork_wholeNetwork_show_timeslider)) {
      return()
    }
    
    if (input$visNetwork_wholeNetwork_show_timeslider == TRUE) {
      dates <-
        c(multiparty.interactions$DateOne.Year,multiparty.interactions$DateTwo.Year)
      dates <- dates[!is.na(dates)]
      
      # Remove an incorrect date
      dates <- dates[dates > 1000]
      
      sliderInput(
        "visNetwork_wholeNetwork_time_period_of_interest", "Time period of interest:",
        min = min(dates) - 1,
        max = max(dates),
        step = 1,
        value = c(min(dates), max(dates))
      )
    }
  })

output$visNetwork_wholeNetwork_HighlightedCategoryUI <- renderUI({
  selectInput(
    'visNetwork_wholeNetwork_highlightedCategory', 'Event/Relation Type to highlight', choices = all_event_categories(), selected = "FamilyRelationships",
    multiple = FALSE
  )
})

output$visNetwork_wholeNetwork_ExcludedCategoriesUI <- renderUI({
  if (is.null(input$visNetwork_wholeNetwork_highlightedCategory)) {
    return()
  }
  
  selectInput(
    'visNetwork_wholeNetwork_ExcludedCategory', 'Event/Relation Type to exclude', choices = c(
      "None",setdiff(
        all_event_types(),
        input$visNetwork_wholeNetwork_highlightedCategory
      )
    ),
    multiple = FALSE
  )
})

output$visNetwork_wholeNetwork_NumberOfExcluded <- renderUI({
  if (is.null(input$visNetwork_wholeNetwork_highlightedCategory)) {
    return()
  }
  
  selected.interactions <- multiparty.interactions
  #  Test suite
  #   visNetwork_wholeNetwork_ExcludedCategory <- "PeerRelationships"
  
  ## Drop excluded categoties from multiparty interactions
  selected.interactions <-
    selected.interactions[selected.interactions$Event.or.Relationship.Type != input$visNetwork_wholeNetwork_ExcludedCategory,]
  
  if (input$visNetwork_wholeNetwork_show_timeslider == TRUE) {
    ## Filter out rows where DateOne.Year is NA or outside of date range
    selected.interactions <-
      selected.interactions[{
        selected.interactions$DateOne.Year >= input$visNetwork_wholeNetwork_time_period_of_interest[1]
      } %in% TRUE &
      {
        selected.interactions$DateOne.Year <= input$visNetwork_wholeNetwork_time_period_of_interest[2]
      } %in% TRUE ,]
    ## Filter out rows where DateTwo.Year is greater than the max date allowd
    selected.interactions <-
      selected.interactions[selected.interactions$DateTwo.Year <= input$visNetwork_wholeNetwork_time_period_of_interest[2] |
                              is.na(selected.interactions$DateTwo.Year),]
    
  }
  
  multiparty.people <-
    unique(
      c(
        multiparty.interactions$Primary.Participant.Emlo_ID,multiparty.interactions$Secondary.Participant.Emlo_ID
      )
    )
  
  selected.people <-
    unique(
      c(
        selected.interactions$Primary.Participant.Emlo_ID, selected.interactions$Secondary.Participant.Emlo_ID
      )
    )
  
  HTML(
    paste0(
      "<p>Included interactions: ",nrow(selected.interactions),"</p>",
      "<p>Included individuals: ",length(selected.people),"</p>",
      "<p>Excluded interactions: ",nrow(multiparty.interactions) - nrow(selected.interactions),"</p>",
      "<p>Excluded individuals: ",length(multiparty.people) - length(selected.people),"</p>"
    )
  )
  
  
})

### ====================================== Generate Network Data =====================================
### ==================================================================================================

visNetwork_wholeNetwork_nodes <- reactive({
  ## Set selected.interactions as all multiparty.interactions
  selected.interactions <- multiparty.interactions
  
  ## Drop excluded categoties from multiparty interactions
  selected.interactions <-
    selected.interactions[selected.interactions$Event.or.Relationship.Type != input$visNetwork_wholeNetwork_ExcludedCategory,]
  
  if (input$visNetwork_wholeNetwork_show_timeslider == TRUE) {
    ## Start experiment area
    
    ## Filter out rows where DateOne.Year is NA or outside of date range
    selected.interactions <-
      selected.interactions[{
        selected.interactions$DateOne.Year >= input$visNetwork_wholeNetwork_time_period_of_interest[1]
      } %in% TRUE &
      {
        selected.interactions$DateOne.Year <= input$visNetwork_wholeNetwork_time_period_of_interest[2]
      } %in% TRUE ,]
    ## Filter out rows where DateTwo.Year is greater than the max date allowd
    selected.interactions <-
      selected.interactions[selected.interactions$DateTwo.Year <= input$visNetwork_wholeNetwork_time_period_of_interest[2] |
                              is.na(selected.interactions$DateTwo.Year),]
    
    ## End Experiment Area
  }
  
  
  ## Apply network.edges.function to selected.interactions
  edges <- network.edges.function(selected.interactions)
  ## Get nodes from edges
  nodes.of.network <-
    unique(c(edges$Primary.Emlo_ID,edges$Secondary.Emlo_ID))
  
  ### ==== Start Experiment
  
  test_nodes_in_people.df <-
    subset(people.df, iperson_id %in% nodes.of.network)$iperson_id
  test_nodes_not_in_people.df <-
    setdiff(nodes.of.network, test_nodes_in_people.df)
  
  ### ==== End Experiment
  
  ## Only include individuals in the people.df data set
  nodes <- subset(people.df, iperson_id %in% nodes.of.network)
  
  visNetwork_nodes <- data.frame(
    "Person.Name" = nodes$Person.Name,
    "Surname" = nodes$Surname,
    "emlo_id" = nodes$iperson_id,
    "color" = rep("lightblue", nrow(nodes))
  )
  ## Return for use
  
  visNetwork_nodes
})

visNetwork_wholeNetwork_edges <- reactive({
  ## Set selected.interactions as all multiparty.interactions
  selected.interactions <- multiparty.interactions
  
  ## Drop excluded categoties from multiparty interactions
  selected.interactions <-
    selected.interactions[selected.interactions$Event.or.Relationship.Type != input$visNetwork_wholeNetwork_ExcludedCategory,]
  
  if (input$visNetwork_wholeNetwork_show_timeslider == TRUE) {
    ## Filter out rows where DateOne.Year is NA or outside of date range
    selected.interactions <-
      selected.interactions[{
        selected.interactions$DateOne.Year >= input$visNetwork_wholeNetwork_time_period_of_interest[1]
      } %in% TRUE &
      {
        selected.interactions$DateOne.Year <= input$visNetwork_wholeNetwork_time_period_of_interest[2]
      } %in% TRUE ,]
    ## Filter out rows where DateTwo.Year is greater than the max date allowd
    selected.interactions <-
      selected.interactions[selected.interactions$DateTwo.Year <= input$visNetwork_wholeNetwork_time_period_of_interest[2] |
                              is.na(selected.interactions$DateTwo.Year),]
  }
  
  
  ## Apply network.edges.function to selected.interactions
  edges <- network.edges.function(selected.interactions)
  ## Get nodes from edges
  nodes.of.network <-
    unique(c(edges$Primary.Emlo_ID,edges$Secondary.Emlo_ID))
  
  ## Subset people.df by nodes in edges
  nodes <- subset(people.df, iperson_id %in% nodes.of.network)
  
  visNetwork_edges <-
    data.frame(
      "source" = as.numeric(
        mapvalues(
          edges$Primary.Emlo_ID, from = nodes$iperson_id, to = 0:(nrow(nodes) - 1),warn_missing = FALSE
        )
      ),
      "target" = as.numeric(
        mapvalues(
          edges$Secondary.Emlo_ID, from = nodes$iperson_id, to = 0:(nrow(nodes) -
                                                                      1),warn_missing = FALSE
        )
      ),
      "source.emlo.id" = as.numeric(edges$Primary.Emlo_ID),
      "target.emlo.id" = as.numeric(edges$Secondary.Emlo_ID),
      ## Times the total number of connections by 10 and add 1 if of the highlighted category type
      ## Allows for testing off oddness for colour and size for the edge width
      "Value" = 20 * edges$Total.Connections + edges[,c(input$visNetwork_wholeNetwork_highlightedCategory)],
      "EdgeColor" = mapvalues(edges[,c(input$visNetwork_wholeNetwork_highlightedCategory)] > 0,c(TRUE,FALSE),c("#ff6666","lightblue"))
    )
  
  ## return for use
  
  visNetwork_edges
})

# output$visNetwork_wholeNetwork_highlighted_node_UI <- renderUI({
#   ## If not loaded yet, stop
#   if (is.null(input$visNetwork_wholeNetwork_highlightedCategory)) {
#     return()
#   }
#   
#   edges <- visNetwork_wholeNetwork_edges()
#   
#   if (is.null(edges)) {
#     return()
#   }
#   
#   visNetwork_nodes <- visNetwork_wholeNetwork_nodes()
#   
#   labels.list <- as.character(visNetwork_nodes$Person.Name)
#   values.list <-
#     as.list(unlist(as.character(visNetwork_nodes$emlo_id)))
#   
#   names(values.list) <- labels.list
#   
#   selectInput(
#     "highlighted.node", label = "Highlight node",
#     choices = values.list, selected = as.character(values.list[1]), multiple = FALSE
#   )
# })

### ====================================== Visualise Entire Network ========================
### ========================================================================================

## show warning if no edges to display
output$whole.network_no_graph <- renderUI({
  ## If not loaded yet, stop
  if (is.null(input$visNetwork_wholeNetwork_show_timeslider)) {
    return()
  }
  
  visN_edges <- visNetwork_wholeNetwork_edges()
  ## If graph.union.fail then the visN_edges is null
  if (is.null(visN_edges)) {
    wellPanel(
      "There are no known interactions between individuals in the dataset, subject to the current filter conditions."
    )
  }
})


output$visNetwork_wholeNetwork <- renderVisNetwork({
  ## If not loaded yet, stop
  
  if (is.null(input$visNetwork_wholeNetwork_highlightedCategory)){
    return()
  }
  
  if (is.null(input$visNetwork_wholeNetwork_show_timeslider)){
    return()
  }
  
  if (is.null(input$visNetwork_wholeNetwork_time_period_of_interest)){
    return()
  }
  
  visNetwork_edges <- visNetwork_wholeNetwork_edges()
  visNetwork_nodes <- visNetwork_wholeNetwork_nodes()
  
  ## Create df for visNetwork
  visN_nodes <- data.frame(
    "id" = visNetwork_nodes$emlo_id,
    "title" = as.character(visNetwork_nodes$Person.Name),
    "label" = as.character(visNetwork_nodes$Surname),
    "color" = as.character(visNetwork_nodes$color)
  )
  
  visN_nodes$color <- as.character(visN_nodes$color)
  
  visN_edges <- data.frame(
    "from" = visNetwork_edges$source.emlo.id,
    "to" = visNetwork_edges$target.emlo.id,
    "color" = visNetwork_edges$EdgeColor,
    "value" = rescale(visNetwork_edges$Value, to = c(2,10))
  )
  
  ## Drop duplicate node:
  visN_nodes <- visN_nodes[!duplicated(visN_nodes$id),]
  
#   visN_nodes[visN_nodes$id == input$highlighted.node,]$color <-
#     "red"
  
  print(visN_nodes$color)
  
  ## Make background colour vector
  node.background.color <- rep("lightblue",nrow(visN_nodes))
#   ## Set highlighted.node to be red
#   node.background.color[visN_nodes$id == input$highlighted.node] <-
#     "red"
#   
  ## Drop edges with nodes not in the node list
  non.conflicting.nodes <-
    intersect(unique(c(visN_edges$from, visN_edges$to)), visN_nodes$id)
  visN_edges <-
    subset(visN_edges, from %in% non.conflicting.nodes &
             to %in% non.conflicting.nodes)
  
  ## Make network
  visNetwork(visN_nodes, visN_edges) %>%
    visNodes(color = list(border = "darkblue"), size = 10) %>%
    visIgraphLayout() %>%
    # visEdges(value = round(rescale(visNetwork_edges$Value, to = c(2,10)))) %>%
    # visEdges(width = 4) %>%
    visInteraction(
      tooltipDelay = 0.2, hideEdgesOnDrag = FALSE, dragNodes = FALSE, dragView = TRUE, zoomView = TRUE
    ) %>%
    visOptions(highlightNearest = TRUE) %>% visLayout(hierarchical = FALSE) %>%
    visInteraction(navigationButtons = TRUE) %>%
    visEvents(selectNode = "function(nodes) {
              Shiny.onInputChange('current_node_id', nodes);
              ;}")
  
  })

output$visNetwork_wholeNetwork_selected_node_info <- renderUI({
  if (is.null(input$current_node_id)) {
    return()
  }
  
  selected.person.name <-
    people.df[people.df$iperson_id == as.numeric(input$current_node_id$nodes[[1]]),"Person.Name"]
  selected.person.name <-
    selected.person.name[!is.na(selected.person.name)]
  
  wellPanel(HTML(
    paste0(
      "<h2>",selected.person.name,"'s Connections</h2>",
      "<p>The table below shows all life events involving the selected individual,
      note the controller allows columns to be added and removed easily.</p>", sep =
        ""
    )
  ))
  
  
})

output$visNetwork_whole_network_connected_life_events_columns_to_show_UI <-
  renderUI({
    tagList(
      selectInput(
        'connected_life_events_Cols', 'Columns to show:',
        usefulCols_life_events, selected = c(
          "Primary.Participant.Name","Secondary.Participant.Name","Event.or.Relationship.Type","DateOne.Year"
        ),
        multiple = TRUE
      ),tags$style(
        type = "text/css", "select#selCategories + .selectize-control{width: 800px}"
      )
    )
  })

output$visNetwork_whole_network_selected_node <-
  DT::renderDataTable({
    #   if(is.null(input$include_interactions_without_dates)){
    #     return()
    #   }
    
    ## Set selected.interactions as all multiparty.interactions
    selected.interactions <- multiparty.interactions
    
    ## Drop excluded categoties from multiparty interactions
    selected.interactions <-
      selected.interactions[selected.interactions$Event.or.Relationship.Type != input$visNetwork_wholeNetwork_ExcludedCategory,]
    
    if (!is.null(input$visNetwork_wholeNetwork_show_timeslider)) {
      ## Filter out rows where DateOne.Year is NA or outside of date range
      selected.interactions <-
        selected.interactions[{
          selected.interactions$DateOne.Year >= input$visNetwork_wholeNetwork_time_period_of_interest[1]
        } %in% TRUE &
        {
          selected.interactions$DateOne.Year <= input$visNetwork_wholeNetwork_time_period_of_interest[2]
        } %in% TRUE ,]
      ## Filter out rows where DateTwo.Year is greater than the max date allowd
      selected.interactions <-
        selected.interactions[selected.interactions$DateTwo.Year <= input$visNetwork_wholeNetwork_time_period_of_interest[2] |
                                is.na(selected.interactions$DateTwo.Year),]
    }
    
    # Drop levels that are empty (as a result of above subsetting)
    selected.interactions <- droplevels(selected.interactions)
    
    # Append a column with the URLS
    
    ## Get selected individual from click
    nodes <- visNetwork_wholeNetwork_nodes()
    selectedIndividual <- as.numeric(input$current_node_id$nodes[[1]])
    
    # Get edges of network
    edges <- visNetwork_wholeNetwork_edges()
    
    
    connectedIndividuals <-
      c(as.character(edges[edges$source.emlo.id == selectedIndividual, "target.emlo.id"]),
        as.character(edges[edges$target.emlo.id == selectedIndividual, "source.emlo.id"]))
    
    # Create an empty data.frame with life.event.columns
    connected_life_events <- selected.interactions[0,]
    # Function to extract connected events
    get.connected.life.events <-
      function(selectedNode, connectedNode) {
        connections <- rbind(selected.interactions[selected.interactions$Primary.Participant.Emlo_ID == selectedNode &
                                                     selected.interactions$Secondary.Participant.Emlo_ID == connectedNode,],
                             selected.interactions[selected.interactions$Primary.Participant.Emlo_ID == connectedNode &
                                                     selected.interactions$Secondary.Participant.Emlo_ID == selectedNode,])
        connected_life_events <<-
          rbind(connected_life_events, connections)
      }
    # lapply function
    invisible(lapply(connectedIndividuals, function(x)
      get.connected.life.events(selectedIndividual, x)))
    
    
    ## Start Experiment
    
    # connected_life_events <- selected.interactiozns[1:5,]
    
    connected_life_events$Primary.Participant.Name <-
      paste0(
        "<a href=http://emlo.bodleian.ox.ac.uk/profile?type=person&id=",
        connected_life_events$Primary.Participant.Emlo_ID,
        ">",
        connected_life_events$Primary.Participant.Name,
        "</a>"
      )
    
    connected_life_events$Secondary.Participant.Name <-
      paste0(
        "<a href=http://emlo.bodleian.ox.ac.uk/profile?type=person&id=",
        connected_life_events$Secondary.Participant.Emlo_ID,
        ">",
        connected_life_events$Secondary.Participant.Name,
        "</a>"
      )
    
    ## End Experiment
    
    # Drop empty rows:
    connected_life_events <-
      connected_life_events[!!rowSums(!is.na(connected_life_events)),]
    # Return
    connected_life_events[,input$connected_life_events_Cols, drop = FALSE]
    
  },escape = FALSE, rownames = FALSE)
