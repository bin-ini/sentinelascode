pipelineJob('SentinelDynamicPipelineRunner') {

    parameters {
            stringParam('jenkinsFileSelected', '...', '...')
        }
        
   description("Placeholder Job for running the dynamic pipelines")
          

    definition {
            cps {
                script(readFileFromWorkspace("../${jenkinsFileSelected}"))
                sandbox()
            }
        }
}
  queue('SentinelDynamicPipelineRunner')
