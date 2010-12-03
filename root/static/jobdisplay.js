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
                display.paintRowIfNeeded(this.uuid);
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
                display.paintRowIfNeeded(this.uuid);
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
                display.paintRowIfNeeded(this.uuid);
                $("#statusBar" + this.uuid).text("Queued...");
                display.getRunning_jobs()[this.uuid] = 1;
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
                display.paintRowIfNeeded(this.job.uuid);
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
                display.paintRowIfNeeded(this.job.uuid);
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
                    message.handleDisplay(this) ; // I love a nice bit of double dispatch
                } catch (ex) {
                    log_it("got unhandled message, exception: '" + ex + "' message : " + dump(m));
                };
            },
            paintRowIfNeeded: function (uuid) {
                if (!this.getRunning_jobs()[uuid]) {
                    $(this.getSelector()).append(
                        '<tr id="' + uuid + '"><td class="uuid">'
                        + uuid + '</td><td class="status" id="statusBar'
                        + uuid + '"></td><td id="progressBar' + uuid + '"></td></tr>'
                    );
                    $("#progressBar" + uuid).progressBar({ boxImage: '/static/images/progressbar.gif', barImage: '/static/images/progressbg.gif'});
                    this.getRunning_jobs()[uuid] = 1;
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
