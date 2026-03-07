<?php
/**
 * SEO Machine — Yoast SEO REST API Extension
 *
 * This MU-plugin exposes Yoast SEO meta fields via the WordPress REST API,
 * allowing SEO Machine to publish content with full SEO metadata via /publish-draft.
 *
 * Installation: Copy to /wp-content/mu-plugins/seo-machine-yoast-rest.php
 *
 * @package SEOMachine
 * @version 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Register Yoast SEO fields for posts via REST API.
 */
add_action( 'rest_api_init', 'seo_machine_register_yoast_fields' );

function seo_machine_register_yoast_fields() {
    $post_types = array( 'post', 'page' );

    foreach ( $post_types as $post_type ) {
        // Meta Title
        register_rest_field(
            $post_type,
            'yoast_meta_title',
            array(
                'get_callback'    => 'seo_machine_get_yoast_title',
                'update_callback' => 'seo_machine_update_yoast_title',
                'schema'          => array(
                    'type'        => 'string',
                    'description' => 'Yoast SEO meta title',
                    'context'     => array( 'view', 'edit' ),
                ),
            )
        );

        // Meta Description
        register_rest_field(
            $post_type,
            'yoast_meta_description',
            array(
                'get_callback'    => 'seo_machine_get_yoast_description',
                'update_callback' => 'seo_machine_update_yoast_description',
                'schema'          => array(
                    'type'        => 'string',
                    'description' => 'Yoast SEO meta description',
                    'context'     => array( 'view', 'edit' ),
                ),
            )
        );

        // Focus Keyword
        register_rest_field(
            $post_type,
            'yoast_focus_keyword',
            array(
                'get_callback'    => 'seo_machine_get_yoast_focus_keyword',
                'update_callback' => 'seo_machine_update_yoast_focus_keyword',
                'schema'          => array(
                    'type'        => 'string',
                    'description' => 'Yoast SEO focus keyword',
                    'context'     => array( 'view', 'edit' ),
                ),
            )
        );
    }
}

// Getters

function seo_machine_get_yoast_title( $post ) {
    return get_post_meta( $post['id'], '_yoast_wpseo_title', true );
}

function seo_machine_get_yoast_description( $post ) {
    return get_post_meta( $post['id'], '_yoast_wpseo_metadesc', true );
}

function seo_machine_get_yoast_focus_keyword( $post ) {
    return get_post_meta( $post['id'], '_yoast_wpseo_focuskw', true );
}

// Updaters

function seo_machine_update_yoast_title( $value, $post ) {
    if ( ! current_user_can( 'edit_post', $post->ID ) ) {
        return new WP_Error( 'rest_forbidden', esc_html__( 'Sorry, you are not allowed to edit this post.' ), array( 'status' => 403 ) );
    }
    update_post_meta( $post->ID, '_yoast_wpseo_title', sanitize_text_field( $value ) );
    return true;
}

function seo_machine_update_yoast_description( $value, $post ) {
    if ( ! current_user_can( 'edit_post', $post->ID ) ) {
        return new WP_Error( 'rest_forbidden', esc_html__( 'Sorry, you are not allowed to edit this post.' ), array( 'status' => 403 ) );
    }
    update_post_meta( $post->ID, '_yoast_wpseo_metadesc', sanitize_textarea_field( $value ) );
    return true;
}

function seo_machine_update_yoast_focus_keyword( $value, $post ) {
    if ( ! current_user_can( 'edit_post', $post->ID ) ) {
        return new WP_Error( 'rest_forbidden', esc_html__( 'Sorry, you are not allowed to edit this post.' ), array( 'status' => 403 ) );
    }
    update_post_meta( $post->ID, '_yoast_wpseo_focuskw', sanitize_text_field( $value ) );
    return true;
}
