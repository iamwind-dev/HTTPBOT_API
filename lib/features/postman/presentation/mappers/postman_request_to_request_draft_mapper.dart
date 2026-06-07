import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_body_draft.dart';
import '../../../request_builder/domain/entities/request_draft.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';
import '../../../request_builder/domain/entities/requests_method.dart';
import '../../domain/entities/postman_auth_entity.dart';
import '../../domain/entities/postman_body_entity.dart';
import '../../domain/entities/postman_key_value_entity.dart';
import '../../domain/entities/postman_request_entity.dart';

class PostmanRequestToRequestDraftMapper {
  const PostmanRequestToRequestDraftMapper();

  RequestDraft call(PostmanRequestEntity request) {
    return RequestDraft(
      method: _mapMethod(request.method),
      url: request.rawUrl,
      queryParameters: request.queryParameters.map(_mapKeyValue).toList(),
      headers: request.headers.map(_mapKeyValue).toList(),
      body: _mapBody(request.body),
      auth: _mapAuth(request.auth),
    );
  }

  HttpMethod _mapMethod(String method) {
    final normalized = method.trim().toUpperCase();
    for (final value in HttpMethod.values) {
      if (value.wireName == normalized || value.label == normalized) {
        return value;
      }
    }

    return HttpMethod.get;
  }

  KeyValueItem _mapKeyValue(PostmanKeyValueEntity item) {
    return KeyValueItem(
      key: item.key,
      value: item.value,
      isEnabled: item.isEnabled,
      type: item.type == PostmanKeyValueType.file
          ? KeyValueItemType.file
          : KeyValueItemType.text,
      contentType: item.contentType,
      description: item.description,
    );
  }

  RequestBodyDraft _mapBody(PostmanBodyEntity body) {
    switch (body.type) {
      case PostmanBodyType.raw:
        return RequestBodyDraft(
          type: RequestBodyType.raw,
          raw: RawBodyDraft(
            subtype: _mapRawSubtype(body.rawSubtype),
            content: body.raw,
          ),
        );
      case PostmanBodyType.formData:
        return RequestBodyDraft(
          type: RequestBodyType.formData,
          formData: body.formData.map(_mapKeyValue).toList(),
        );
      case PostmanBodyType.urlEncoded:
        return RequestBodyDraft(
          type: RequestBodyType.xWwwFormUrlEncoded,
          urlEncoded: body.urlEncoded.map(_mapKeyValue).toList(),
        );
      case PostmanBodyType.graphQl:
        return RequestBodyDraft(
          type: RequestBodyType.graphql,
          graphQl: GraphQlBodyDraft(
            query: body.graphQlQuery,
            variables: body.graphQlVariables,
          ),
        );
      case PostmanBodyType.none:
      case PostmanBodyType.file:
        return const RequestBodyDraft.none();
    }
  }

  RawBodySubtype _mapRawSubtype(PostmanRawBodySubtype subtype) {
    switch (subtype) {
      case PostmanRawBodySubtype.json:
        return RawBodySubtype.json;
      case PostmanRawBodySubtype.xml:
        return RawBodySubtype.xml;
      case PostmanRawBodySubtype.html:
        return RawBodySubtype.html;
      case PostmanRawBodySubtype.text:
      case PostmanRawBodySubtype.javascript:
        return RawBodySubtype.text;
    }
  }

  RequestAuthDraft _mapAuth(PostmanAuthEntity auth) {
    switch (auth.type) {
      case PostmanAuthType.basic:
        return RequestAuthDraft(
          type: AuthType.basic,
          basic: BasicAuthDraft(
            username: auth.basic.username,
            password: auth.basic.password,
          ),
        );
      case PostmanAuthType.apiKey:
        return RequestAuthDraft(
          type: AuthType.apiKey,
          apiKey: ApiKeyAuthDraft(
            name: auth.apiKey.key,
            value: auth.apiKey.value,
            location: _mapApiKeyLocation(auth.apiKey.location),
          ),
        );
      case PostmanAuthType.bearerToken:
        return RequestAuthDraft(
          type: AuthType.bearerToken,
          bearerToken: BearerTokenAuthDraft(
            token: auth.bearerToken.token,
            prefix: auth.bearerToken.prefix,
          ),
        );
      case PostmanAuthType.digest:
        return RequestAuthDraft(
          type: AuthType.digest,
          digest: DigestAuthDraft(
            username: auth.digest.username,
            password: auth.digest.password,
            realm: auth.digest.realm,
            nonce: auth.digest.nonce,
            algorithm: auth.digest.algorithm.isEmpty
                ? 'MD5'
                : auth.digest.algorithm,
            qop: auth.digest.qop,
            opaque: auth.digest.opaque,
          ),
        );
      case PostmanAuthType.hawk:
        return RequestAuthDraft(
          type: AuthType.hawk,
          hawk: HawkAuthDraft(
            identifier: auth.hawk.identifier,
            key: auth.hawk.key,
            algorithm: auth.hawk.algorithm.isEmpty
                ? 'sha256'
                : auth.hawk.algorithm,
            app: auth.hawk.app,
            delegation: auth.hawk.delegation,
          ),
        );
      case PostmanAuthType.jwt:
        return RequestAuthDraft(
          type: AuthType.jwt,
          jwt: JwtAuthDraft(
            token: auth.jwt.token,
            header: auth.jwt.header,
            payload: auth.jwt.payload,
            secret: auth.jwt.secret,
            algorithm: auth.jwt.algorithm.isEmpty
                ? 'HS256'
                : auth.jwt.algorithm,
            prefix: auth.jwt.prefix,
          ),
        );
      case PostmanAuthType.ntlm:
        return RequestAuthDraft(
          type: AuthType.ntlm,
          ntlm: NtlmAuthDraft(
            username: auth.ntlm.username,
            password: auth.ntlm.password,
            domain: auth.ntlm.domain,
            workstation: auth.ntlm.workstation,
          ),
        );
      case PostmanAuthType.awsSignature:
        return RequestAuthDraft(
          type: AuthType.awsSignature,
          aws: AwsAuthDraft(
            accessKey: auth.aws.accessKey,
            secretKey: auth.aws.secretKey,
            region: auth.aws.region,
            service: auth.aws.service,
            sessionToken: auth.aws.sessionToken,
          ),
        );
      case PostmanAuthType.oauth1:
        return RequestAuthDraft(
          type: AuthType.oauth1,
          oauth1: OAuth1AuthDraft(
            consumerKey: auth.oauth1.consumerKey,
            consumerSecret: auth.oauth1.consumerSecret,
            token: auth.oauth1.token,
            tokenSecret: auth.oauth1.tokenSecret,
            signatureMethod: auth.oauth1.signatureMethod.isEmpty
                ? 'HMAC-SHA1'
                : auth.oauth1.signatureMethod,
            nonce: auth.oauth1.nonce,
            timestamp: auth.oauth1.timestamp,
            version: auth.oauth1.version.isEmpty ? '1.0' : auth.oauth1.version,
          ),
        );
      case PostmanAuthType.oauth2:
        return RequestAuthDraft(
          type: AuthType.oauth2,
          oauth2: OAuth2AuthDraft(
            accessToken: auth.oauth2.accessToken,
            refreshToken: auth.oauth2.refreshToken,
            clientId: auth.oauth2.clientId,
            clientSecret: auth.oauth2.clientSecret,
            tokenUrl: auth.oauth2.tokenUrl,
            scopes: auth.oauth2.scopes,
          ),
        );
      case PostmanAuthType.none:
        return const RequestAuthDraft.none();
    }
  }

  ApiKeyLocation _mapApiKeyLocation(PostmanApiKeyLocation location) {
    switch (location) {
      case PostmanApiKeyLocation.query:
        return ApiKeyLocation.query;
      case PostmanApiKeyLocation.cookie:
        return ApiKeyLocation.cookie;
      case PostmanApiKeyLocation.header:
        return ApiKeyLocation.header;
    }
  }
}
