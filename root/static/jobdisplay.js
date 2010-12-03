Module("CatalystX.JobServer.JobRunner.Forked.WorkerStatus", function (m) {
    Class("CompletionEstimate", {
        does: Joose.Storage,
        has: {
            step_count: {
                is: "ro",
                init: 0
            },
            steps_taken: {
                is: "ro",
                init: 0
            },
            uuid: {
                is: "ro",
            }
        },
        methods: {
            handleDisplay: function( display ) {
                var percentage = Math.floor(100 * parseInt(this.steps_taken) / parseInt(this.step_count));
                $("#progressBar" + this.uuid).progressBar(percentage, { boxImage: '/static/images/progressbar.gif', barImage: '/static/images/progressbg.gif'});
            }
        }
    });
    Class("StatusLine", {
        does: Joose.Storage,
        has: {
            status_info: {
                is: "ro",
                init: ""
            },
            uuid: {
                is: "ro",
            }
        },
        methods: {
            handleDisplay: function( display ) {
                $("#statusBar" + this.uuid).text(this.getStatus_info());
            }
        }
    });
    Class("RunJob", {
        does: Joose.Storage,
        has: {
            uuid: {
                is: "ro",
            },
            job: {
                is: "ro",
            },
        },
        methods: {
            handleDisplay: function( display ) {
                $(display.getSelector()).append('<tr id="' + this.job.uuid + '"><td class="uuid">'
                    + this.job.uuid + '</td><td class="status" id="statusBar' + this.job.uuid + '"></td><td id="progressBar'
                    + this.job.uuid + '"></td></tr>');
                $("#statusBar" + this.job.uuid).text("Queued...");
                display.getRunning_jobs()[this.job.uuid] = 1;
            }
        }
    });
});
Module("CatalystX.JobServer.Job", function (m) {
    Class("Running", {
        does: Joose.Storage,
        has: {
            job: {
                is: "ro",
            },
        },
        methods: {
            handleDisplay: function( display ) {
                $("#statusBar" + this.job.uuid).text("Started new job");
            }
        }
    });
    Class("Finished", {
        does: Joose.Storage,
        has: {
            job: {
                is: "ro",
            },
            progress_bar_selector: {
               is: "rw",
            }
        },
        methods: {
            handleDisplay: function( display ) {
                $("#progressBar" + this.job.uuid).progressBar(100);
                delete display.getRunning_jobs()[this.job.uuid];
            }
        }
    });
});

Module("CatalystX.JobServer.JobDisplay", function (m) {
   Class("Hippie", {
       has: {
           hippie: {
               is: "ro",
               init: function () {
                   var that = this;
                   new Hippie(
                       document.location.host,
                       5, // Timeout
                       function() { that.connected() },
                       function() { that.disconnected() },
                       function(e) { that.handleMessage(e) },
                       that.hippie_path                                                  
                   );
               },
               lazy: 1
           },
           running_jobs: {
               is: "ro",
               init: {},
           },
           selector: {
               is: "ro"
           }
       },
       methods: {
           handleMessage: function (m) {
               var message;
               try {
                     message = Joose.Storage.Unpacker.unpack(m);
                     if (!this.getRunning_jobs()[message.uuid]) {
                         $(this.getSelector()).append('<tr id="' + message.uuid + '"><td class="uuid">' + message.uuid + '</td><td class="status" id="statusBar' + message.uuid + '"></td><td id="progressBar' + message.uuid + '"></td></tr>');
                         $("#progressBar" + message.uuid).progressBar({ boxImage: '/static/images/progressbar.gif', barImage: '/static/images/progressbg.gif'});
                         this.getRunning_jobs()[message.uuid] = 1;
                    }
                     
                    message.handleDisplay(this); // I love a nice bit of double dispatch
                 } catch (ex) {
                     log_it("got unhandled message, exception: " + ex + " message : " + dump(m));
                 }
           },
           connected: function () {},
           disconnected: function () {},
           displayInside: function (selector, hippie_path) {
               this.selector = selector;
               this.hippie_path = hippie_path;
               this.getHippie();
               $(this.selector)
           }
       }
   });
});
     
function log_it(stuff) {
  $("#log").append(stuff+'<br/>');
}
