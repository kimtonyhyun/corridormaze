classdef CorridorMaze < handle
    properties (SetAccess=private)
        corridor_state
        params
    end
    
    properties (Hidden=true)
        a % Arduino object
    end
    
    methods
        function maze = CorridorMaze(comPort)
            % Set up parameters
            %------------------------------------------------------------
            
            % Map JP label on breakout board to corridor index
            jp_to_corridor = [1 3 2 4];
                              
            % JP1
            p.corridor(jp_to_corridor(1)).step = 53;  % Dir is expected to be pin "step"-2
            p.corridor(jp_to_corridor(1)).dose = 49;
            p.corridor(jp_to_corridor(1)).dose_duration = 40;
            p.corridor(jp_to_corridor(1)).lick = 47;
            
            % JP2
            p.corridor(jp_to_corridor(2)).step = 52;
            p.corridor(jp_to_corridor(2)).dose = 48;
            p.corridor(jp_to_corridor(2)).dose_duration = 40;
            p.corridor(jp_to_corridor(2)).lick = 46;
            
            % JP3
            p.corridor(jp_to_corridor(3)).step = 29;
            p.corridor(jp_to_corridor(3)).dose = 25;
            p.corridor(jp_to_corridor(3)).dose_duration = 40; % ms
            p.corridor(jp_to_corridor(3)).lick = 23;
            
            % JP4
            p.corridor(jp_to_corridor(4)).step = 28;
            p.corridor(jp_to_corridor(4)).dose = 24;
            p.corridor(jp_to_corridor(4)).dose_duration = 40;
            p.corridor(jp_to_corridor(4)).lick = 22;
            
            p.num_corridors = length(p.corridor);
            
            % Synchronization outputs
            p.sync.miniscope_trig = 13;
            p.sync.foot_pedal = 12;
            
            maze.params = p;
            
            % Establish access to Arduino
            %------------------------------------------------------------
            maze.a = arduino(comPort);

            % Set up digital pins
            for i = 1:length(maze.params.corridor)
                corridor = maze.params.corridor(i);
                maze.a.pinMode(corridor.step, 'output');
                maze.a.pinMode(corridor.step-2, 'output'); % dir
                maze.a.pinMode(corridor.dose, 'output');
                maze.a.pinMode(corridor.lick, 'input');
            end
            
            maze.a.pinMode(maze.params.sync.miniscope_trig, 'output');
            maze.a.pinMode(maze.params.sync.foot_pedal, 'input');
            
            % Assume all corridors are in the plate position (0), rather
            %   than the mesh position (1)
            %------------------------------------------------------------
            maze.corridor_state = [0 0 0 0];
             
        end
        
        function miniscope_start(maze)
            maze.a.digitalWrite(maze.params.sync.miniscope_trig, 1);
        end
        
        function miniscope_stop(maze)
            maze.a.digitalWrite(maze.params.sync.miniscope_trig, 0);
        end
        
        function press = pedal_is_pressed(maze)
            val = maze.a.digitalRead(maze.params.sync.foot_pedal);
            press = (val == 1);
        end
        
        function dose(maze, corridor_ind)
            c = maze.params.corridor(corridor_ind); % Selected corridor
            maze.a.send_pulse(c.dose, c.dose_duration);
        end % dose
        
        function lick = is_licking(maze, corridor_ind)
            lick_pin = maze.params.corridor(corridor_ind).lick;
            val = maze.a.digitalRead(lick_pin);
            lick = (val == 0); % HW pin goes low for lick
        end % is_licking
        
        function lick_state = get_lick_state(maze)
            lick_state = zeros(1, maze.params.num_corridors);
            for i = 1:maze.params.num_corridors
                lick_state(i) = maze.is_licking(i);
            end
        end % get_lick_state
        
        function set_corridor(maze, corridor_ind, target)
            % target == 0: Go to steel plate
            % target == 0.5: 90 deg
            % target == 1: Go to mesh
            step_pin = maze.params.corridor(corridor_ind).step;

            current = maze.corridor_state(corridor_ind);
            if (target ~= current)
                direction = (target > current);
                num_90degs = abs(target-current)*2;
                maze.a.rotate_stepper(step_pin, direction, num_90degs);
            end
            
            maze.corridor_state(corridor_ind) = target;
        end % set_corridor
        
        function flip_corridor(maze, corridor_ind)
            current = maze.corridor_state(corridor_ind);
            if (current == 0)
                target = 1;
            else
                target = 0;
            end
            maze.set_corridor(corridor_ind, target);
            
            maze.corridor_state(corridor_ind) = target;
        end % flip_corridor
        
        function reset_corridors(maze)
            % Set all corridors to 0 (steel plate)
            for i = 1:maze.params.num_corridors
                maze.set_corridor(i, 0);
            end
        end % reset_corridors
    end
end