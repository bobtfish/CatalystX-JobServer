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
            }
        },
        methods: {
            handleDisplay: function( display ) {
                var percentage = Math.floor(100 * parseInt(this.steps_taken) / parseInt(this.step_count));
                $(display.getRunning_jobs()[this.uuid].getProgress_bar_selector()).progressBar(percentage);
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
        },
        methods: {
            handleDisplay: function( display ) {
                $(display.getRunning_jobs()[this.uuid].getStatus_bar_selector()).text(this.getStatus_info());
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
            progress_bar_selector: {
                is: "rw",
            },
            status_bar_selector: {
                is: "rw"
            }
        },
        methods: {
            handleDisplay: function( display ) {
                this.setProgress_bar_selector('#progressBar' + this.job.uuid);
                this.setStatus_bar_selector('#statusBar' + this.job.uuid);
                $(display.getSelector()).append('<tr id="' + this.job.uuid + '"><td class="uuid">' + this.job.uuid + '</td><td class="status" id="statusBar' + this.job.uuid + '"></td><td class="progress" id="progressBar' + this.job.uuid + '"></td></tr>');
                $(this.progress_bar_selector).progressBar({ boxImage: '/static/images/progressbar.gif', barImage: '/static/images/progressbg.gif'});
                display.getRunning_jobs()[this.job.uuid] = this;
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
                $(display.getRunning_jobs()[this.uuid].getProgress_bar_selector()).progressBar(100);
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
