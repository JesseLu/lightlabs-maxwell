%% maxwell_urlreadwrite
% Initiates an http or https connection to a server.
% Uses a custom Certificate authority that validates only a specific
% self-signed ssl connection for https connections.
% Requires the Maxwell java library to obtain the MaxwellTrustManager object.

function [urlConnection, errorid, errormsg] = maxwell_urlreadwrite(urlChar, varargin)
    % Default output arguments.
    urlConnection = [];
    errorid = '';
    errormsg = '';

    % Determine the protocol (before the ":").
    protocol = urlChar(1:min(find(urlChar==':'))-1);

    % Try to use the native handler, not the ice.* classes.
    switch protocol
        case 'http'
            try
                handler = sun.net.www.protocol.http.Handler;
            catch exception %#ok
                handler = [];
            end
        case 'https'
            handler = sun.net.www.protocol.https.Handler;
        otherwise
            handler = [];
    end

    % Create the URL object.
    try
        if isempty(handler)
            url = java.net.URL(urlChar);
        else
            url = java.net.URL([],urlChar,handler);
        end
    catch exception %#ok
        errorid = ['InvalidUrl'];
        errormsg = 'Either this URL could not be parsed or the protocol is not supported.';
        return
    end

    % Get the proxy information using MathWorks facilities for unified proxy
    % prefence settings.
    mwtcp = com.mathworks.net.transport.MWTransportClientPropertiesFactory.create();
    proxy = mwtcp.getProxy(); 


    % For some reason, we have to do this twice...
    for k = 1 : 2
        % Open a connection to the URL.
        if isempty(proxy)
            urlConnection = url.openConnection;
        else
            urlConnection = url.openConnection(proxy);
        end

        % Allow a single self-signed certificate.
        if strcmp(protocol, 'https')
            sc = javax.net.ssl.SSLContext.getInstance('SSL');
            if isempty(varargin)
                maxwellCertManager = MaxwellTrustManager.getManager();
            else
                maxwellCertManager = MaxwellTrustManager.getManager(varargin{1});
            end
            sc.init([], maxwellCertManager, java.security.SecureRandom());
            urlConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
        end
    end

    % Set timeout.
    urlConnection.setConnectTimeout(5e3); % 5-second window to establish connection.
    urlConnection.setReadTimeout(120e3); % 2-minute window to read from connection.
end

