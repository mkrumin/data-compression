% borrowed from here:
% https://uk.mathworks.com/matlabcentral/answers/523891-how-to-get-drive-name

function    drive_name = DriveName( drive_letter ) 
    cmd_str = sprintf( 'vol %s:', drive_letter );
    [~,msg] = system( cmd_str );
    cac = strsplit( msg, '\n' );
    drive_name = regexp( cac{1}, '(?<= is ).+$', 'match', 'once' );
end