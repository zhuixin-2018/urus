/**
 *   tcprstat -- Extract stats about TCP response times
 *   Copyright (C) 2010  Ignacio Nin
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
**/

#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <signal.h>
#include <pthread.h>
#include <string.h>
#include <time.h>
#include <errno.h>

#include "tcprstat.h"
#include "functions.h"
#include "local-addresses.h"
#include "capture.h"
#include "output.h"
#include "stats.h"

struct option long_options[] = {
    { "help", no_argument, NULL, 'h' },
    { "version", no_argument, NULL, 'V' },
    
    { "local", required_argument, NULL, 'l' },
    { "port", required_argument, NULL, 'p' },
    { "format", required_argument, NULL, 'f' },
    { "header", optional_argument, NULL, 's' },
    { "no-header", no_argument, NULL, 'S' },
    { "interval", required_argument, NULL, 't' },
    { "iterations", required_argument, NULL, 'n' },
    { "read", required_argument, NULL, 'r' },

    { NULL, 0, NULL, '\0' }

};
char *short_options = "hVp:f:t:n:r:l:";

int specified_addresses = 0;

pthread_t capture_thread_id, output_thread_id;

// Global options
char *program_name;
int port;
int interval = 30;
FILE *capture_file = NULL;
struct output_options output_options = {
    DEFAULT_OUTPUT_FORMAT,
    DEFAULT_OUTPUT_INTERVAL,
    DEFAULT_OUTPUT_ITERATIONS,
    
    DEFAULT_SHOW_HEADER,
    NULL,
    
};

// Operation timestamp
time_t timestamp;

int
main(int argc, char *argv[]) {
    struct sigaction sa;
    char c;
    int option_index = 0;
    
    // Program name
    program_name = strrchr(argv[0], '/');
    if (program_name)
        program_name ++;
    else
        program_name = argv[0];
        
    // Parse command line options
    do {
        c = getopt_long(argc, argv, short_options, long_options, &option_index);

        switch (c) {

        case (char)-1:
            break;
            
        case 'r':
            capture_file = fopen(optarg, "r");
            if (!capture_file) {
                fprintf(stderr, "Cannot open file `%s': %s\n", optarg,
                        strerror(errno));
                return EXIT_FAILURE;
                
            }
            break;
            
        case 'l':
            specified_addresses = 1;
            if (parse_addresses(optarg)) {
                fprintf(stderr, "Error parsing local addresses\n");
                return EXIT_FAILURE;
                
            }
            
            break;
            
        case 'p':
            port = strtol(optarg, NULL, 0);
            if (port <= 0 || port > 65535) {
                fprintf(stderr, "Invalid port\n");
                return EXIT_FAILURE;
            }
            
            break;
            
        case 'f':
            if (!check_format(optarg)) {
                fprintf(stderr, "Bad format provided: `%s'\n", optarg);
                return EXIT_FAILURE;
            }
            
            output_options.format = optarg;
            
            break;
            
        case 't':
            output_options.interval = strtoul(optarg, NULL, 10);
            if (interval <= 0 || interval >= MAX_OUTPUT_INTERVAL) {
                fprintf(stderr, "Bad interval provided\n");
                return EXIT_FAILURE;
            }
            
            break;
            
        case 'n':
            output_options.iterations = strtol(optarg, NULL, 10);
            if (interval < 0) {
                fprintf(stderr, "Bad iterations provided\n");
                return EXIT_FAILURE;
            }
            
            break;
            
        case 's':
            output_options.header = optarg;
            output_options.show_header = 1;
            break;
            
        case 'S':
            output_options.show_header = 0;
            break;
            
        case 'h':
            dump_help(stdout);
            return EXIT_SUCCESS;

        case 'V':
            dump_version(stdout);
            return EXIT_SUCCESS;

        default:
            dump_usage(stderr);
            return EXIT_FAILURE;

        }

    }
    while (c != (char)-1);
    
    // Set up signals
    sa.sa_handler = terminate;
    sigemptyset(&sa.sa_mask);
    sigaddset(&sa.sa_mask, SIGTERM);
    sigaddset(&sa.sa_mask, SIGINT);
    sa.sa_flags = 0;
    sa.sa_restorer = NULL;
    
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    
    // Get local addresses
    if (!specified_addresses && get_addresses() != 0)
        return EXIT_FAILURE;
    
    // Operations timestamp
    time(&timestamp);
    
    // Stats
    init_stats();
    
    if (capture_file) {
        output_offline_start(&output_options);

        offline_capture(capture_file);
        
        fclose(capture_file);
        
    }
    else {
        // Fire up capturing thread
        pthread_create(&capture_thread_id, NULL, capture, NULL);
        
        // Options thread
        pthread_create(&output_thread_id, NULL, output_thread, &output_options);
        
        pthread_join(capture_thread_id, NULL);
        pthread_kill(output_thread_id, SIGINT);
        
    }
        
    free_stats();
    free_addresses();
    
    return EXIT_SUCCESS;

}

void
terminate(int signal) {
    endcapture();
        
}
