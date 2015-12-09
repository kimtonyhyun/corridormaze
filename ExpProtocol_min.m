function ExpProtocol_min(maze, mode)
% "Minimal" implementation of the CorridorMaze experimental protocol
%
% Inputs
%   - maze: CorridorMaze object
%   - mode: 1 to reward mesh side, 0 for solid side

trial = 1; % Number of correct trials
last_detected_pos = 0;
last_rewarded_pos = 0;

% Assign random start positions for servos
if flip_coin()
    maze.set_corridor(1,1);
    maze.set_corridor(2,0);
else
    maze.set_corridor(1,0);
    maze.set_corridor(2,1);
end

if flip_coin()
    maze.set_corridor(3,1);
    maze.set_corridor(4,0);
else
    maze.set_corridor(3,0);
    maze.set_corridor(4,1);
end

% Ready to begin!
disp('All platforms in place and acquisition board initialized. Press any key to continue.')
pause;

% Trigger image acquistion
maze.miniscope_start();

% Start mouse trials
while trial < 1000
    for i = 1:maze.params.num_corridors
        if (maze.is_licking(i) && (i ~= last_detected_pos))
            last_detected_pos = i;
            
            % Correct lick?
            correct_lick = (maze.corridor_state(i) == mode);
            if correct_lick
                % open water valve for specified time (replaced while loop)
                maze.dose(i);
                last_rewarded_pos = i;

                % assign new platform positions based on pseudo random numbers
                % platform positions are flipped 50% of the time
                if (i<=2)
                    maze.set_corridor(3,0.5);
                    maze.set_corridor(4,0.5);
                    if flip_coin()
                        maze.set_corridor(3,1);
                        maze.set_corridor(4,0);
                    else
                        maze.set_corridor(3,0);
                        maze.set_corridor(4,1);
                    end
                else
                    maze.set_corridor(1,0.5);
                    maze.set_corridor(2,0.5);
                    if flip_coin()
                        maze.set_corridor(1,1);
                        maze.set_corridor(2,0);
                    else
                        maze.set_corridor(1,0);
                        maze.set_corridor(2,1);
                    end
                end

                % increment number of trials/ correct trials
                fprintf('Trial %d: Correct lick at %d!\n', trial, i);
                trial = trial+1;

            else % Incorrect lick
                if (last_rewarded_pos ~= 0)
                    maze.set_corridor(last_rewarded_pos, 0.5);
                end
                
                fprintf('  Detected incorrect lick at Corridor %i!\n', i);
            end % correct lick
        end
    end % Loop corridors

    % Check if the pedal is pressed
%     if maze.pedal_is_pressed()
%         fprintf('  Detected pedal press. Terminating!\n');
%         maze.miniscope_stop();
%         break;
%     end
    
end % Loop trials

end % ExpProtocol_min

function coin = flip_coin()
    coin = 0.5 < rand(1);
end % flip_coin