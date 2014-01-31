<?php

/**
 * Implements hook_form_FORM_ID_alter().
 *
 * Allows the profile to alter the site configuration form.
 */
function ***MACHINE_NAME***_form_install_configure_form_alter(&$form, $form_state) {
  // Hide some messages from various modules that are just too chatty.
  drupal_get_messages('status');
  drupal_get_messages('warning');

  // Set reasonable defaults for site configuration form
  $form['site_information']['site_name']['#default_value'] = '***HUMAN_NAME***';
  $form['admin_account']['account']['name']['#default_value'] = 'admin';
  $form['server_settings']['site_default_country']['#default_value'] = 'US';
  $form['server_settings']['date_default_timezone']['#default_value'] = 'America/Los_Angeles'; // West coast, best coast

  // Define a default email address if we can guess a valid one
  if (valid_email_address('admin@' . $_SERVER['HTTP_HOST'])) {
    $form['site_information']['site_mail']['#default_value'] = 'admin@' . $_SERVER['HTTP_HOST'];
    $form['admin_account']['account']['mail']['#default_value'] = 'admin@' . $_SERVER['HTTP_HOST'];
  }

  // Call the hook_form_alter from l10n_install profile.
  require_once(DRUPAL_ROOT . '/profiles/l10n_install/l10n_install.profile');
  l10n_install_form_install_configure_form_alter($form, $form_state);
}

/**
 * Implements hook_install_tasks()
 */
function ***MACHINE_NAME***_install_tasks(&$install_state) {
  $tasks = array();

  // Add our custom CSS file for the installation process
  drupal_add_css(drupal_get_path('profile', '***MACHINE_NAME***') . '/panopoly.css');

  // Add the Panopoly app selection to the installation process
  $panopoly_server = array(
    'machine name' => 'panopoly',
    'default apps' => array('panopoly_demo'),
    'default content callback' => '***MACHINE_NAME***_default_content',
  );
  require_once(drupal_get_path('module', 'apps') . '/apps.profile.inc');
  $tasks = $tasks + apps_profile_install_tasks($install_state, $panopoly_server);

  // Add Localization tasks to the installation process.
  require_once(DRUPAL_ROOT . '/profiles/l10n_install/l10n_install.profile');
  $tasks = $tasks + l10n_install_install_tasks($install_state);

  return $tasks;
}

/**
 * Implements hook_install_tasks_alter()
 */
function ***MACHINE_NAME***_install_tasks_alter(&$tasks, $install_state) {
  // Remove core steps for translation imports.
  require_once(DRUPAL_ROOT . '/profiles/l10n_install/l10n_install.profile');
  l10n_install_install_tasks_alter($tasks, $install_state);

  // Magically go one level deeper in solving years of dependency problems
  require_once(drupal_get_path('module', 'panopoly_core') . '/panopoly_core.profile.inc');
  $tasks['install_load_profile']['function'] = 'panopoly_core_install_load_profile';
}

/**
 * Implements hook_form_FORM_ID_alter()
 */
function ***MACHINE_NAME***_form_apps_profile_apps_select_form_alter(&$form, $form_state) {

  // For some things there are no need
  $form['apps_message']['#access'] = FALSE;
  $form['apps_fieldset']['apps']['#title'] = NULL;

  // Improve style of apps selection form
  if (isset($form['apps_fieldset'])) {
    $manifest = apps_manifest(apps_servers('panopoly'));
    foreach ($manifest['apps'] as $name => $app) {
      if ($name != '#theme') {
        $form['apps_fieldset']['apps']['#options'][$name] = '<strong>' . $app['name'] . '</strong><p><div class="admin-options"><div class="form-item">' . theme('image', array('path' => $app['logo']['path'], 'height' => '32', 'width' => '32')) . '</div>' . $app['description'] . '</div></p>';
      }
    }
  }
}

/**
 * Implements hook_form_alter().
 * Uses system prefix to work around https://drupal.org/node/1153646
 */
function system_form_install_select_locale_form_alter(&$form, &$form_state, $form_id) {
  // Hint the user at how to get localization support for more languages.
  drupal_set_message('In order to add localization support for more languages, copy the corresponding .po file from the l10n_install profile translations folder to the ***MACHINE_NAME*** profile translations folder.');
}

/**
 * Apps installer default content callback.
 */
function ***MACHINE_NAME***_default_content(&$modules) {
  // TODO: It would be better to figure out which apps have demo content
  // modules by looking at the app manifest. Unfortunately, this doesn't qute
  // work because the manifest doesn't know about the default content module
  // until the app has actually been enabled, since that data only comes in
  // from hook_apps_app_info().
  //
  // apps_include('manifest');
  // $apps = apps_apps('panopoly');
  // foreach ($modules as $module) {
  //   if (!empty($apps[$module]['demo content module'])) {
  //     $modules[] = $apps[$module]['demo content module'];
  //   }
  // }
  //
  // This workaround assumes a pattern MYMODULE_demo.
  $files = system_rebuild_module_data();
  foreach($modules as $module) {
    if (isset($files[$module . '_demo'])) {
      $modules[] = $module . '_demo';
    }
  }
}
