function MassiveGenerator(mask, lin_scale, H, prob_jumps, time_steps, args)

arguments
    mask (1, :) {mustBeNonnegative, mustBeInteger}
    lin_scale (1, 1) {mustBePositive}
    H = []
    prob_jumps (1, :) {mustBePositive}...
        = [0.1:0.1:0.5, 1/6, 0.01, 0.25, 1/3]
    time_steps (1, :) {mustBePositive, mustBeInteger}...
        = 1e4:1e4:1e5
    args.StartPosition = []
    args.UseGPU (1, 1) logical = ~isempty(gpuDevice)
    args.Verbosity = true
end


disp = @(str) MyDisp(args.Verbosity, str);

if isempty(H)
    H = ceil(6*log(10)/log(numel(mask)));
end

struct_tag = "{" + join(string(mask), "-") + "_" +  lin_scale + "}";

%% Run


full_run_count = numel(prob_jumps) * numel(time_steps);
run_number = 0;

time_start = tic;
date_start = string(datetime());
for time_step = time_steps
    for prob_jump = prob_jumps
        %% Display info       
        
        run_tag = "{p = " + prob_jump + ", t = " + time_step + "}";
        
        disp("Started on:        " + date_start);
        
        disp("Date now:          " + string(datetime()))
        disp("Structure:         " + struct_tag)
        disp("Running:           " + run_tag)
        
        average_run_time = toc(time_start) / run_number;
        if ~isinf(average_run_time)
            disp("Expected run time: " + Dur2String(average_run_time))
            disp("Expected run end:  " +...
                string(datetime() + seconds(average_run_time)));
        end
        
        time_this_run_start = tic;
        
        
        %% Return probability construction
        
        butdiff.ReturnProbabilityConstructor(...
            mask, lin_scale, H, prob_jump, time_step,...
            "StartPosition", args.StartPosition,...
            "UseGPU", args.UseGPU);

        
        %% Display info
        
        time_this_run_duration = toc(time_this_run_start);
        
        disp("Finished:          " + run_tag)

        disp("Time of run:       " + Dur2String(time_this_run_duration))       
        
        disp("Time total:        " + Dur2String(toc(time_start)))
        
        if time_this_run_duration > 1
            run_number  = run_number + 1;
        else
            time_this_run_duration = nan;
        end
        
        average_passed_time_per_run =...
            mean([toc(time_start) / run_number, time_this_run_duration],...
            "omitnan");
        expected_time_total = average_passed_time_per_run * full_run_count;
        expected_time_left = expected_time_total - toc(time_start);

        expected_finish = datetime() + seconds(expected_time_left);
        
        if ~isinf(expected_time_left)
            disp("Expected time:     " + Dur2String(expected_time_left))
            disp("Expected end:      " + string(expected_finish))
        end
        
        disp("* * * * * * * * * * * * * * * * * * * * *")
    end
end
end


%% Functions

function dur_str = Dur2String(sec_count)

if isinf(sec_count) || isnan(sec_count)
    dur_str = " unknown";
    return
end

% ms
if sec_count < 1
    dur_str = (sec_count * 1000) + " ms";
    return
end

% s
if sec_count < 60
    dur_str = sec_count + " s";
    return
end

% min
if sec_count < 60*60
    dur_str = (sec_count / 60) + " min";
    return
end

% h
if sec_count < 60*60*24
    dur_str = (sec_count /60 /60) + " h";
    return
end

% day
dur_str = (sec_count /60 /60 /24) + " day";
end


function MyDisp(verbosity, str)

if verbosity
    disp(str)
end
end
