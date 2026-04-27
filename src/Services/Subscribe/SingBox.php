<?php

declare(strict_types=1);

namespace App\Services\Subscribe;

use App\Services\Subscribe;
use App\Utils\Tools;
use function array_filter;
use function array_merge;
use function json_decode;
use function json_encode;

final class SingBox extends Base
{
    public function getContent($user): string
    {
        $nodes = [];
        $singbox_config = $_ENV['SingBox_Config'];
        $nodes_raw = Subscribe::getUserNodes($user);

        foreach ($nodes_raw as $node_raw) {
            $node_custom_config = json_decode($node_raw->custom_config, true);

            switch ((int) $node_raw->sort) {
                case 0:
                    $node = [
                        'type' => 'shadowsocks',
                        'tag' => $node_raw->name,
                        'server' => $node_raw->server,
                        'server_port' => (int) $user->port,
                        'method' => $user->method,
                        'password' => $user->passwd,
                    ];

                    break;
                case 1:
                    $ss_2022_port = $node_custom_config['offset_port_user'] ??
                        ($node_custom_config['offset_port_node'] ?? 443);
					$host = $node_custom_config['host'] ?? '';	
                    $method = $node_custom_config['method'] ?? '2022-blake3-aes-128-gcm';
                    $user_pk = Tools::genSs2022UserPk($user->passwd, $method);
					$server_key = $node_custom_config['server_key'] ?? '';
					$allow_insecure = $node_custom_config['allow_insecure'] ?? true;
					
                    if (! $user_pk) {
                        $node = [];
                        break;
                    }
					
					$node = [
						'tag' => $node_raw->name,
                        'type' => 'shadowsocks',
                        'detour' => $node_raw->name . '-shadowtls',
						'method' => $method, 
                        'password' => $server_key === '' ? $user_pk : $server_key . ':' .$user_pk,												
                    ];
                    $node_extra = [
						'tag' => $node_raw->name . '-shadowtls',
                        'type' => 'shadowtls',
                        'server' => $node_raw->server,
                        'server_port' => 443,
                        'version' => 3,                     
						'password' => '123456',
						'tls' => [ 
							'enabled' => true,
                            'server_name' => $host,
                            'utls' => [
								'enabled' => true,
								'fingerprint' => 'chrome',
							],
                        ],
                    ];
			
					// 👉 先 push 主节点（让 selector 先看到它）
					$nodes[] = $node;
					$singbox_config['outbounds'][0]['outbounds'][] = $node['tag'];
					$singbox_config['outbounds'][1]['outbounds'][] = $node['tag'];

					// 👉 再 push shadowtls（底层链路）
					$nodes[] = $node_extra;
					$singbox_config['outbounds'][0]['outbounds'][] = $node_extra['tag'];
					$singbox_config['outbounds'][1]['outbounds'][] = $node_extra['tag'];

					// ⚠️ 阻止外部再 push 一次
					$node = [];
					
                    break;
                case 2:
                    $tuic_port = $node_custom_config['offset_port_user'] ??
                        ($node_custom_config['offset_port_node'] ?? 443);
                    $host = $node_custom_config['host'] ?? '';
                    $allow_insecure = $node_custom_config['allow_insecure'] ?? false;
                    $congestion_control = $node_custom_config['congestion_control'] ?? 'bbr';

                    $node = [
                        'type' => 'tuic',
                        'tag' => $node_raw->name,
                        'server' => $node_raw->server,
                        'server_port' => (int) $tuic_port,
                        'uuid' => $user->uuid,
                        'password' => $user->passwd,
                        'congestion_control' => $congestion_control,
                        'zero_rtt_handshake' => true,
                        'tls' => [
                            'enabled' => true,
                            'server_name' => $host,
                            'insecure' => (bool) $allow_insecure,
                        ],
                    ];

                    $node['tls'] = array_filter($node['tls']);

                    break;
                case 11:
					$v2_port = $node_custom_config['offset_port_user'] ??
						($node_custom_config['offset_port_node'] ?? 443);
					$transport = ($node_custom_config['network'] ?? '') === 'tcp'
						? 'tcp'
						: ($node_custom_config['network'] ?? 'tcp');
					$host = $node_custom_config['header']['request']['headers']['Host'][0] ??
						$node_custom_config['host'] ?? '';
					$path = $node_custom_config['header']['request']['path'][0] ??
						$node_custom_config['path'] ?? '/';
					$headers = $node_custom_config['header']['request']['headers'] ?? [];
					$service_name = $node_custom_config['servicename'] ?? '';
					$allow_insecure = $node_custom_config['allow_insecure'] ?? false;
					$method = $node_custom_config['method'] ?? 'GET';
					$max_early_data = (int)($node_custom_config['max_early_data'] ?? 0);
					$early_data_header_name = $node_custom_config['early_data_header_name'] ?? 'Sec-WebSocket-Protocol';

					// ✅ server_name 兜底
					$server_name = $host ?: $node_raw->server;

					// ✅ 修复 headers（Host 不能是数组）
					if (isset($headers['Host']) && is_array($headers['Host'])) {
						$headers['Host'] = $headers['Host'][0];
					}
					// =========================
					// ✅ transport 按类型构建
					// =========================
					$transportConfig = [];

					switch ($transport) {

						case 'ws':
							$transportConfig = [
								'type' => 'ws',
								'path' => $path ?: '/',
								'headers' => !empty($headers) ? $headers : [
									'Host' => $server_name,
								],
								'max_early_data' => $max_early_data,
								'early_data_header_name' => $early_data_header_name,
							];
							break;
							
						case 'grpc':
							$transportConfig = [
								'type' => 'grpc',
								'service_name' => $service_name ?: 'grpc',
							];
							break;

						case 'quic':
							$transportConfig = [
								'type' => 'quic',
							];
							break;

						case 'http':
							$transportConfig = [
								'type' => 'http',
								'host' => $server_name,
								'path' => $path ?: '/',
								'method' => $method ?: 'GET',
								'headers' => $headers,
							];
							break;
						
						case 'httpupgrade':
							$transportConfig = [
								'type' => 'httphttpupgrade',
								'host' => $server_name,
								'path' => $path ?: '/',								
								'headers' => $headers,
							];
							break;

						case 'tcp':
							$transportConfig = [];
						default:
							$transportConfig = [];
							break;
					}					
					// =========================
					// ✅ 最终节点
					// =========================
					$node = [
						'type' => 'vmess',
						'tag' => $node_raw->name,
						'server' => $node_raw->server,
						'server_port' => (int)$v2_port,
						'uuid' => $user->uuid,
						'security' => 'auto',
						'alter_id' => 0,
						'tls' => [
                            'enabled' => true,
                            'server_name' => $host,
							'insecure' => (bool) $allow_insecure,
							'utls' => [
								'enabled' => true,
								'fingerprint' => 'chrome',
							],
                        ],
						// 性能优化（推荐保留）
						'packet_encoding' => 'xudp',
						'global_padding' => true,
						'authenticated_length' => true,
						'transport' => $transportConfig,
					];					

					break;
                case 14:
                    $trojan_port = $node_custom_config['offset_port_user'] ??
                        ($node_custom_config['offset_port_node'] ?? 443);
                    $host = $node_custom_config['host'] ?? '';
                    $allow_insecure = $node_custom_config['allow_insecure'] ?? '0';
                    $transport = $node_custom_config['network'] ?? '';
                    $path = $node_custom_config['header']['request']['path'][0] ?? $node_custom_config['path'] ?? '';
                    $headers = $node_custom_config['header']['request']['headers'] ?? [];
                    $service_name = $node_custom_config['servicename'] ?? '';
					// ✅ server_name 兜底
					$server_name = $host ?: $node_raw->server;

					// ✅ 修复 headers（Host 不能是数组）
					if (isset($headers['Host']) && is_array($headers['Host'])) {
						$headers['Host'] = $headers['Host'][0];
					}
					// =========================
					// ✅ transport 按类型构建
					// =========================
					$transportConfig = [];

					switch ($transport) {

						case 'ws':
							$transportConfig = [
								'type' => 'ws',
								'path' => $path ?: '/',
								'headers' => !empty($headers) ? $headers : [
									'Host' => $server_name,
								],
								'max_early_data' => $max_early_data,
								'early_data_header_name' => $early_data_header_name,
							];
							break;
							
						case 'grpc':
							$transportConfig = [
								'type' => 'grpc',
								'service_name' => $service_name ?: 'grpc',
							];
							break;

						case 'quic':
							$transportConfig = [
								'type' => 'quic',
							];
							break;

						case 'http':
							$transportConfig = [
								'type' => 'http',
								'host' => $server_name,
								'path' => $path ?: '/',
								'method' => $method ?: 'GET',
								'headers' => $headers,
							];
							break;
						
						case 'httpupgrade':
							$transportConfig = [
								'type' => 'httphttpupgrade',
								'host' => $server_name,
								'path' => $path ?: '/',								
								'headers' => $headers,
							];
							break;

						case 'tcp':
							$transportConfig = [];
						default:
							$transportConfig = [];
							break;
					}					
					// =========================
					// ✅ 最终节点
					// =========================
                    $node = [
                        'type' => 'trojan',
                        'tag' => $node_raw->name,
                        'server' => $node_raw->server,
                        'server_port' => (int) $trojan_port,
                        'password' => $user->uuid,
                        'tls' => [
                            'enabled' => true,
                            'server_name' => $host,
                            'insecure' => (bool) $allow_insecure,
                        ],
                        'transport' => $transportConfig,
                    ];

                    $node['tls'] = array_filter($node['tls']);
                    $node['transport'] = array_filter($node['transport']);

                    break;
                default:
                    $node = [];
                    break;
            }

            if ($node === []) {
                continue;
            }

            $nodes[] = $node;
            $singbox_config['outbounds'][0]['outbounds'][] = $node_raw->name;
            $singbox_config['outbounds'][1]['outbounds'][] = $node_raw->name;
        }

        $singbox_config['outbounds'] = array_merge($singbox_config['outbounds'], $nodes);
        $singbox_config['experimental']['cache_file']['cache_id'] = $_ENV['appName'];

        return json_encode($singbox_config);
    }
}
