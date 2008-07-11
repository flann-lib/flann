/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpConst;

/*******************************************************************************

        Constants

*******************************************************************************/

struct HttpConst
{
        const char[] Eol = "\r\n";
}

/*******************************************************************************

        Headers are distinct types in their own right. This is because they
        are somewhat optimized via a trailing ':' character.

*******************************************************************************/

struct HttpHeaderName
{
        final char[] value;  
}

/*******************************************************************************

        Define the traditional set of HTTP header names
        
*******************************************************************************/

struct HttpHeader
{   
        // size of both the request & response buffer (per thread)
        const int IOBufferSize                 = 16 * 1024;

        // maximum length for POST parameters (to avoid DOS ...)
        const int MaxPostParamSize             = 4 * 1024;

        const HttpHeaderName Version           = {"HTTP/1.0"};
        const HttpHeaderName TextHtml          = {"text/html"};

        const HttpHeaderName Accept            = {"Accept:"};
        const HttpHeaderName AcceptCharset     = {"Accept-Charset:"};
        const HttpHeaderName AcceptEncoding    = {"Accept-Encoding:"};
        const HttpHeaderName AcceptLanguage    = {"Accept-Language:"};
        const HttpHeaderName AcceptRanges      = {"Accept-Ranges:"};
        const HttpHeaderName Age               = {"Age:"};
        const HttpHeaderName Allow             = {"Allow:"};
        const HttpHeaderName Authorization     = {"Authorization:"};
        const HttpHeaderName CacheControl      = {"Cache-Control:"};
        const HttpHeaderName Connection        = {"Connection:"};
        const HttpHeaderName ContentEncoding   = {"Content-Encoding:"};
        const HttpHeaderName ContentLanguage   = {"Content-Language:"};
        const HttpHeaderName ContentLength     = {"Content-Length:"};
        const HttpHeaderName ContentLocation   = {"Content-Location:"};
        const HttpHeaderName ContentRange      = {"Content-Range:"};
        const HttpHeaderName ContentType       = {"Content-Type:"};
        const HttpHeaderName Cookie            = {"Cookie:"};
        const HttpHeaderName Date              = {"Date:"};
        const HttpHeaderName ETag              = {"ETag:"};
        const HttpHeaderName Expect            = {"Expect:"};
        const HttpHeaderName Expires           = {"Expires:"};
        const HttpHeaderName From              = {"From:"};
        const HttpHeaderName Host              = {"Host:"};
        const HttpHeaderName Identity          = {"Identity:"};
        const HttpHeaderName IfMatch           = {"If-Match:"};
        const HttpHeaderName IfModifiedSince   = {"If-Modified-Since:"};
        const HttpHeaderName IfNoneMatch       = {"If-None-Match:"};
        const HttpHeaderName IfRange           = {"If-Range:"};
        const HttpHeaderName IfUnmodifiedSince = {"If-Unmodified-Since:"};
        const HttpHeaderName LastModified      = {"Last-Modified:"};
        const HttpHeaderName Location          = {"Location:"};
        const HttpHeaderName MaxForwards       = {"Max-Forwards:"};
        const HttpHeaderName MimeVersion       = {"MIME-Version:"};
        const HttpHeaderName Pragma            = {"Pragma:"};
        const HttpHeaderName ProxyAuthenticate = {"Proxy-Authenticate:"};
        const HttpHeaderName ProxyConnection   = {"Proxy-Connection:"};
        const HttpHeaderName Range             = {"Range:"};
        const HttpHeaderName Referrer          = {"Referer:"};
        const HttpHeaderName RetryAfter        = {"Retry-After:"};
        const HttpHeaderName Server            = {"Server:"};
        const HttpHeaderName ServletEngine     = {"Servlet-Engine:"};
        const HttpHeaderName SetCookie         = {"Set-Cookie:"};
        const HttpHeaderName SetCookie2        = {"Set-Cookie2:"};
        const HttpHeaderName TE                = {"TE:"};
        const HttpHeaderName Trailer           = {"Trailer:"};
        const HttpHeaderName TransferEncoding  = {"Transfer-Encoding:"};
        const HttpHeaderName Upgrade           = {"Upgrade:"};
        const HttpHeaderName UserAgent         = {"User-Agent:"};
        const HttpHeaderName Vary              = {"Vary:"};
        const HttpHeaderName Warning           = {"Warning:"};
        const HttpHeaderName WwwAuthenticate   = {"WWW-Authenticate:"};
}


/*******************************************************************************

        Declare the traditional set of HTTP response codes

*******************************************************************************/

enum HttpResponseCode
{       
        Continue                     = 100,
        SwitchingProtocols           = 101,
        OK                           = 200,
        Created                      = 201,
        Accepted                     = 202,
        NonAuthoritativeInformation  = 203,
        NoContent                    = 204,
        ResetContent                 = 205,
        PartialContent               = 206,
        MultipleChoices              = 300,
        MovedPermanently             = 301,
        MovedTemporarily             = 302,
        SeeOther                     = 303,
        NotModified                  = 304,
        UseProxy                     = 305,
        TemporaryRedirect            = 307,
        BadRequest                   = 400,
        Unauthorized                 = 401,
        PaymentRequired              = 402,
        Forbidden                    = 403,
        NotFound                     = 404,
        MethodNotAllowed             = 405,
        NotAcceptable                = 406,
        ProxyAuthenticationRequired  = 407,
        RequestTimeout               = 408,
        Conflict                     = 409,
        Gone                         = 410,
        LengthRequired               = 411,
        PreconditionFailed           = 412,
        RequestEntityTooLarge        = 413,
        RequestURITooLarge           = 414,
        UnsupportedMediaType         = 415,
        RequestedRangeNotSatisfiable = 416,
        ExpectationFailed            = 417,
        InternalServerError          = 500,
        NotImplemented               = 501,
        BadGateway                   = 502,
        ServiceUnavailable           = 503,
        GatewayTimeout               = 504,
        VersionNotSupported          = 505,
};

/*******************************************************************************

        Status is a compound type, with a name and a code.

*******************************************************************************/

struct HttpStatus
{
        final int     code; 
        final char[]  name;  
}

/*******************************************************************************

        Declare the traditional set of HTTP responses

*******************************************************************************/

struct HttpResponses
{       
        static HttpStatus Continue                     = {HttpResponseCode.Continue, "Continue"};
        static HttpStatus SwitchingProtocols           = {HttpResponseCode.SwitchingProtocols, "SwitchingProtocols"};
        static HttpStatus OK                           = {HttpResponseCode.OK, "OK"};
        static HttpStatus Created                      = {HttpResponseCode.Created, "Created"};
        static HttpStatus Accepted                     = {HttpResponseCode.Accepted, "Accepted"};
        static HttpStatus NonAuthoritativeInformation  = {HttpResponseCode.NonAuthoritativeInformation, "NonAuthoritativeInformation"};
        static HttpStatus NoContent                    = {HttpResponseCode.NoContent, "NoContent"};
        static HttpStatus ResetContent                 = {HttpResponseCode.ResetContent, "ResetContent"};
        static HttpStatus PartialContent               = {HttpResponseCode.PartialContent, "PartialContent"};
        static HttpStatus MultipleChoices              = {HttpResponseCode.MultipleChoices, "MultipleChoices"};
        static HttpStatus MovedPermanently             = {HttpResponseCode.MovedPermanently, "MovedPermanently"};
        static HttpStatus MovedTemporarily             = {HttpResponseCode.MovedTemporarily, "MovedTemporarily"};
        static HttpStatus SeeOther                     = {HttpResponseCode.SeeOther, "SeeOther"};
        static HttpStatus NotModified                  = {HttpResponseCode.NotModified, "NotModified"};
        static HttpStatus UseProxy                     = {HttpResponseCode.UseProxy, "UseProxy"};
        static HttpStatus BadRequest                   = {HttpResponseCode.BadRequest, "BadRequest"};
        static HttpStatus Unauthorized                 = {HttpResponseCode.Unauthorized, "Unauthorized"};
        static HttpStatus PaymentRequired              = {HttpResponseCode.PaymentRequired, "PaymentRequired"};
        static HttpStatus Forbidden                    = {HttpResponseCode.Forbidden, "Forbidden"};
        static HttpStatus NotFound                     = {HttpResponseCode.NotFound, "NotFound"};
        static HttpStatus MethodNotAllowed             = {HttpResponseCode.MethodNotAllowed, "MethodNotAllowed"};
        static HttpStatus NotAcceptable                = {HttpResponseCode.NotAcceptable, "NotAcceptable"};
        static HttpStatus ProxyAuthenticationRequired  = {HttpResponseCode.ProxyAuthenticationRequired, "ProxyAuthenticationRequired"};
        static HttpStatus RequestTimeout               = {HttpResponseCode.RequestTimeout, "RequestTimeout"};
        static HttpStatus Conflict                     = {HttpResponseCode.Conflict, "Conflict"};
        static HttpStatus Gone                         = {HttpResponseCode.Gone, "Gone"};
        static HttpStatus LengthRequired               = {HttpResponseCode.LengthRequired, "LengthRequired"};
        static HttpStatus PreconditionFailed           = {HttpResponseCode.PreconditionFailed, "PreconditionFailed"};
        static HttpStatus RequestEntityTooLarge        = {HttpResponseCode.RequestEntityTooLarge, "RequestEntityTooLarge"};
        static HttpStatus RequestURITooLarge           = {HttpResponseCode.RequestURITooLarge, "RequestURITooLarge"};
        static HttpStatus UnsupportedMediaType         = {HttpResponseCode.UnsupportedMediaType, "UnsupportedMediaType"};
        static HttpStatus RequestedRangeNotSatisfiable = {HttpResponseCode.RequestedRangeNotSatisfiable, "RequestedRangeNotSatisfiable"};
        static HttpStatus ExpectationFailed            = {HttpResponseCode.ExpectationFailed, "ExpectationFailed"};
        static HttpStatus InternalServerError          = {HttpResponseCode.InternalServerError, "InternalServerError"};
        static HttpStatus NotImplemented               = {HttpResponseCode.NotImplemented, "NotImplemented"};
        static HttpStatus BadGateway                   = {HttpResponseCode.BadGateway, "BadGateway"};
        static HttpStatus ServiceUnavailable           = {HttpResponseCode.ServiceUnavailable, "ServiceUnavailable"};
        static HttpStatus GatewayTimeout               = {HttpResponseCode.GatewayTimeout, "GatewayTimeout"};
        static HttpStatus VersionNotSupported          = {HttpResponseCode.VersionNotSupported, "VersionNotSupported"};
}
