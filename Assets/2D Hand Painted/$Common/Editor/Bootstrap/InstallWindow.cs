using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEditor.PackageManager.Requests;
using UnityEditor.Presets;
using UnityEngine;
using UnityEngine.Rendering;
using Object = UnityEngine.Object;

namespace NotSlot.HandPainted2D.Editor
{
  internal sealed partial class InstallWindow : EditorWindow
  {
    #region Constants

    private const int PACKS_COUNT = 6;

    private const short INSTALLER_VERSION = 1;

    private const short TAGS_LAYERS_VERSION = 1;

    private const string ROOT_FOLDER = "Assets/2D Hand Painted";

    private const string COMMON_FOLDER = ROOT_FOLDER + "/$Common";

    private const string TAGS_PRESET = ROOT_FOLDER + "/TagsLayers.preset";

    private const string BOOTSTRAP_FOLDER = COMMON_FOLDER + "/Editor/Bootstrap";

    private const string TEMP_MENU_SCRIPT = BOOTSTRAP_FOLDER + "/TempMenu.cs";

    private const float PADDING = 12;

    private static readonly Vector2 WINDOW_SIZE = new Vector2(580, 420);

    private static readonly Rect CONTENT_RECT =
      new Rect(PADDING, 88, WINDOW_SIZE.x - 2 * PADDING, WINDOW_SIZE.y - 153);

    private static GUIStyle STYLE_HEADER;

    private static GUIStyle STYLE_STEP_ACTIVE;

    private static GUIStyle STYLE_STEP_NORMAL;

    private static GUIStyle STYLE_RICH;

    private static GUIStyle STYLE_RICH_SMALL;

    private static GUIStyle STYLE_ENJOY_BUTTON;

    private static GUIStyle STYLE_ERROR;

    private static Color COLOR_STEP_PENDING;

    private static Color COLOR_STEP_CURRENT;

    private static Color COLOR_STEP_COMPLETE;

    private static Color COLOR_DIVIDER;

    private static Texture2D LOGO_NORMAL;

    private static Texture2D LOGO_HOVER;

    private static Texture2D CHECK_FALSE;

    private static Texture2D CHECK_TRUE;

    private static readonly string[] STEPS =
    {
      "Intro", "Config", "Install", "Enjoy!"
    };

    #endregion


    #region Fields

    private int _step = 0;

    private bool _continue = true;

    private bool _isProgress = false;

    private bool _disableForceInstall;

    private string _title;

    private readonly List<PackMeta> _pendingPacks = new List<PackMeta>();

    private BundleMeta _bundleMeta;

    private Pipeline _pipeline;

    private bool _configLayers = true;

    private bool _configPackageShapes = true;

    private readonly List<Action> _tasks = new List<Action>();

    private bool _initTasks = true;

    private bool _nextTask = false;

    private int _currentTask = -1;

    private static bool _checkPendingInstall;

    private string _manualLink;

    private string _titleCache;

    private static int _urpAssetsCount;

    #endregion


    #region EditorWindow

    private void OnEnable ()
    {
      titleContent = new GUIContent("Package Installer");
      minSize = WINDOW_SIZE;
      maxSize = WINDOW_SIZE;
      wantsMouseMove = true;

      _bundleMeta = BundleMeta.GetAsset();
      string[] guids =
        AssetDatabase.FindAssets("t:PackMeta", new[] { ROOT_FOLDER });
      foreach ( string guid in guids )
      {
        string path = AssetDatabase.GUIDToAssetPath(guid);
        PackMeta meta = AssetDatabase.LoadAssetAtPath<PackMeta>(path);
        if ( _bundleMeta.GetVersion(meta.Name) < meta.InstallerVersion )
          _pendingPacks.Add(meta);
      }

      switch ( _pendingPacks.Count )
      {
        case PACKS_COUNT:
          _title = "2D Hand Painted Bundle";
          break;
        case 1:
          _title = $"{_pendingPacks[0].Name} 2D Hand Painted Pack";
          break;
        default:
          _title = "2D Hand Painted Packs";
          break;
      }
    }

    private void OnGUI ()
    {
      Config();
      DrawHeader();

      switch ( _step )
      {
        case 0:
          StepIntro();
          break;
        case 1:
          StepConfig();
          break;
        case 2:
          StepInstall();
          break;
        case 3:
          StepEnjoy();
          break;
      }

      DrawFooter();
      if ( Event.current.type == EventType.MouseMove )
        Repaint();
    }

    private void OnDestroy ()
    {
      if ( _disableForceInstall || _step == STEPS.Length - 1 )
        return;

      EditorApplication.update += ShowInstaller;
    }

    #endregion


    #region Methods

    [InitializeOnLoadMethod]
    private static void Init ()
    {
#if !HANDPAINTED2D_SANDBOX
      EditorApplication.update += CheckPendingInstallation;
#endif
    }

    private static void CheckPendingInstallation ()
    {
      if ( !_checkPendingInstall )
      {
        _checkPendingInstall = true;
        return;
      }

      EditorApplication.update -= CheckPendingInstallation;

      bool needInstaller = false;
      string[] guids =
        AssetDatabase.FindAssets("t:PackMeta", new[] { ROOT_FOLDER });
      if ( guids.Length == 0 )
        return;

      BundleMeta bundleMeta = BundleMeta.GetAsset();
      if ( bundleMeta.HasAnotherPack(INSTALLER_VERSION) )
      {
        SkipInstallation(bundleMeta, guids);
        return;
      }
      
      foreach ( string guid in guids )
      {
        string path = AssetDatabase.GUIDToAssetPath(guid);
        PackMeta meta = AssetDatabase.LoadAssetAtPath<PackMeta>(path);
        if ( bundleMeta.GetVersion(meta.Name) >= meta.InstallerVersion )
          continue;

        needInstaller = true;
        break;
      }

      if ( needInstaller )
        EditorApplication.update += ShowInstaller;
#if !HANDPAINTED2D_SANDBOX
      else
        AssetDatabase.DeleteAsset(TEMP_MENU_SCRIPT);
#endif
    }

    private static void ShowInstaller ()
    {
      EditorApplication.update -= ShowInstaller;
      GetWindow<InstallWindow>(true).Show();
    }

    private static void Config ()
    {
      if ( STYLE_HEADER != null )
        return;

      STYLE_HEADER = new GUIStyle
      {
        fontSize = 22,
        fontStyle = FontStyle.Bold,
        alignment = TextAnchor.MiddleCenter,
        normal = new GUIStyleState
        {
          textColor = EditorGUIUtility.isProSkin
            ? EditorStyles.largeLabel.normal.textColor
            : new Color(0.14f, 0.15f, 0.16f)
        }
      };

      STYLE_STEP_ACTIVE = new GUIStyle(EditorStyles.label)
      {
        alignment = TextAnchor.MiddleCenter,
        fontSize = 14,
        fontStyle = FontStyle.Bold
      };

      STYLE_STEP_NORMAL = new GUIStyle(STYLE_STEP_ACTIVE)
      {
        fontStyle = FontStyle.Normal,
        normal = new GUIStyleState
        {
          textColor = EditorGUIUtility.isProSkin
            ? new Color(0.54f, 0.55f, 0.56f)
            : new Color(0.46f, 0.45f, 0.44f)
        }
      };

      STYLE_RICH = new GUIStyle(EditorStyles.label)
      {
        richText = true,
        alignment = TextAnchor.UpperLeft,
        wordWrap = true,
        fontSize = 14,
      };

      STYLE_RICH_SMALL = new GUIStyle(STYLE_RICH)
      {
        fontSize = 12
      };

      STYLE_ENJOY_BUTTON = new GUIStyle("button")
      {
        // richText = true,
        wordWrap = true,
        fontSize = 14,
      };

      STYLE_ERROR = new GUIStyle(EditorStyles.label)
      {
        fontStyle = FontStyle.Italic,
        normal = new GUIStyleState
        {
          textColor = Color.red
        }
      };

      COLOR_STEP_PENDING = EditorGUIUtility.isProSkin
        ? new Color(0.14f, 0.14f, 0.14f)
        : new Color(0.86f, 0.86f, 0.86f);

      COLOR_STEP_CURRENT = EditorGUIUtility.isProSkin
        ? new Color(58 / 255f, 121 / 255f, 187 / 255f)
        : new Color(60 / 255f, 118 / 255f, 191 / 255f);

      COLOR_STEP_COMPLETE = EditorGUIUtility.isProSkin
        ? new Color(70 / 255f, 90 / 255f, 100 / 255f)
        : new Color(155 / 255f, 185 / 255f, 215 / 255f);

      COLOR_DIVIDER = EditorGUIUtility.isProSkin
        ? new Color(0.16f, 0.17f, 0.18f)
        : new Color(0.74f, 0.73f, 0.72f);

      LOGO_NORMAL = AssetDatabase.LoadAssetAtPath<Texture2D>(
        $"{BOOTSTRAP_FOLDER}/logo.png");

      LOGO_HOVER = AssetDatabase.LoadAssetAtPath<Texture2D>(
        $"{BOOTSTRAP_FOLDER}/logo-hover.png");

      CHECK_FALSE = AssetDatabase.LoadAssetAtPath<Texture2D>(
        $"{BOOTSTRAP_FOLDER}/check-false.png");

      CHECK_TRUE = AssetDatabase.LoadAssetAtPath<Texture2D>(
        $"{BOOTSTRAP_FOLDER}/check-true.png");
    }

    private void DrawHeader ()
    {
      Rect rect = new Rect(PADDING, 0, WINDOW_SIZE.x - 2 * PADDING, 46);
      GUI.Label(rect, string.IsNullOrEmpty(_titleCache) ? _title : _titleCache,
                STYLE_HEADER);
      rect.y += 44;

      int stepsCount = STEPS.Length;
      float segmentWidth =
        (WINDOW_SIZE.x - 4 * (stepsCount - 1) - 2 * PADDING) / stepsCount;
      for ( int i = 0; i < 4; i++ )
      {
        // Title
        Rect label = new Rect(rect.x, rect.y, segmentWidth, 28);
        GUI.Label(label, STEPS[i],
                  i == _step ? STYLE_STEP_ACTIVE : STYLE_STEP_NORMAL);

        // Line
        Color color;
        if ( i > _step )
          color = COLOR_STEP_PENDING;
        else if ( i == _step )
          color = COLOR_STEP_CURRENT;
        else
          color = COLOR_STEP_COMPLETE;

        Rect line = new Rect(rect.x, rect.y + 28, segmentWidth, 2);
        EditorGUI.DrawRect(line, color);

        rect.x += segmentWidth + 4;
      }
    }

    private void DrawFooter ()
    {
      Rect rect = new Rect(PADDING, WINDOW_SIZE.y - 2 * PADDING - 29,
                           WINDOW_SIZE.x - 2 * PADDING, 1);
      EditorGUI.DrawRect(rect, COLOR_DIVIDER);

      rect.y += PADDING + 1;
      rect.height = 28;

      Rect logo = rect;
      logo.width = 33;
      Texture image = logo.Contains(Event.current.mousePosition)
        ? LOGO_HOVER
        : LOGO_NORMAL;
      EditorGUIUtility.AddCursorRect(logo, MouseCursor.Link);
      if ( GUI.Button(logo, image, GUIStyle.none) )
        Application.OpenURL("https://notslot.com");

      if ( _step >= STEPS.Length - 1 )
        return;

      EditorGUI.BeginDisabledGroup(!_continue);

      Rect button = rect;
      button.width = 100;
      button.x += rect.width - 100;
      if ( GUI.Button(button, _isProgress ? "Installing..." : "Continue") )
        _step++;

      EditorGUI.EndDisabledGroup();
    }

    private void StepIntro ()
    {
      string text = $"<b>Thank you for downloading the {_title}!</b>\n\n" +
                    "The following screens will guide you through configuring and installing the assets to best suit your needs.";

      _pipeline = DetectPipeline();
      switch ( _pipeline )
      {
        case Pipeline.UniversalForward:
          _continue = false;
          _disableForceInstall = true;
          text +=
            "\n\n<color=orange>Please configure the Universal Render Pipeline’s renderer to <b>2D Renderer</b>.</color>";
          break;
        case Pipeline.BuiltIn:
          _continue = false;
          _disableForceInstall = true;
          text +=
            "\n\n<color=red>Built-in (standard) Renderer is not supported. Please install and configure a Universal Render Pipeline.</color>";
          break;
        case Pipeline.Hd:
          _continue = false;
          _disableForceInstall = true;
          text +=
            "\n\n<color=red>High-definition Render Pipeline is not supported. Please install and configure a Universal Render Pipeline.</color>";
          break;
        case Pipeline.Unrecognized:
          _continue = false;
          _disableForceInstall = true;
          text +=
            "\n\n<color=red>This Render Pipeline is not supported. Please install and configure a Universal Render Pipeline.</color>";
          break;
        case Pipeline.Universal2D:
          if ( _urpAssetsCount > 1 )
            text +=
              "\n\n<color=yellow>Make sure to delete unused Render Pipeline Assets to prevent corrupted rendering.</color>";
          goto default;
        default:
          _continue = true;
          _disableForceInstall = false;
          break;
      }

      if ( _continue == false )
        text +=
          "\n\nAfter configuring the render pipeline, you can open this Installer window through the menu `2D Hand Painted / Install`.";
      else
        text += "\n\n<i>It may take a few minutes...</i>";

      // https://docs.unity3d.com/Packages/com.unity.ugui@1.0/manual/StyledText.html
      Rect textRect = CONTENT_RECT;
      textRect.height -= 85;
      GUI.Label(textRect, text, STYLE_RICH);

      if ( _continue )
        return;

#if UNITY_2021_1_OR_NEWER
      string buttonLink =
        "https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@11.0/manual/Setup.html";
#elif UNITY_2020_1_OR_NEWER
      string buttonLink =
        "https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@10.4/manual/Setup.html";
#else
      string buttonLink =
        "https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@7.6/manual/Setup.html";
#endif

      Rect buttonRect = textRect;
      buttonRect.height = 60;
      buttonRect.x = buttonRect.width / 4;
      buttonRect.width /= 2;
      buttonRect.y = textRect.y + textRect.height + 15;

      if ( GUI.Button(buttonRect, "Pipeline Setup Guide", STYLE_ENJOY_BUTTON) )
        Application.OpenURL(buttonLink);
    }

    private void StepConfig ()
    {
      GUI.BeginGroup(CONTENT_RECT);

      string pipelineName = null;
      switch ( _pipeline )
      {
        case Pipeline.BuiltIn:
          pipelineName = "Built-in";
          break;
        case Pipeline.Universal2D:
          pipelineName = "Universal (2D)";
          break;
      }

      GUILayout.Label("Render Pipeline", EditorStyles.boldLabel);
      GUILayout.Label(
        $"Detected render pipeline: <b>{pipelineName} Render Pipeline</b>, assets will be configured accordingly.",
        STYLE_RICH_SMALL);

      EditorGUILayout.Space();

      _configLayers = EditorGUILayout.ToggleLeft(
        "Tags & Layers preset", _configLayers, EditorStyles.boldLabel);
      GUILayout.Label(
        "Our demo scenes use the following sorting layers: Background, Default, and Foreground.");
      if ( !_configLayers )
        GUILayout.Label(
          "Without using the Tags & Layers preset the demo scenes will not display correctly.",
          STYLE_ERROR);

      EditorGUILayout.Space();

      GUILayout.Label("Install Dependencies", EditorStyles.boldLabel);

      _configPackageShapes = EditorGUILayout.ToggleLeft(
        "2D Sprite Shapes", _configPackageShapes);
      if ( !_configPackageShapes )
        GUILayout.Label(
          "Sprite Shapes package is required to use the shapes provided by this asset.\nDemo scenes will not display correctly.",
          STYLE_ERROR);

      GUI.EndGroup();
    }

    private void StepInstall ()
    {
      int taskCount = 0;
      string pipelineName =
        _pipeline == Pipeline.BuiltIn ? "Built-in" : "Universal 2D";

      Rect rect = CONTENT_RECT;
      rect.height = 18;
      rect.x += PADDING;
      rect.y += PADDING;

      void Task (string text, bool count = true)
      {
        Rect check = rect;
        check.width = 18;

        bool completed = !count || taskCount++ < _currentTask;
        GUI.DrawTexture(check, completed ? CHECK_TRUE : CHECK_FALSE);

        Rect label = rect;
        label.width -= 24;
        label.x += 24;
        GUI.Label(label, text);

        rect.y += 28;
      }

      // Pipeline
      // if ( _pipeline == Pipeline.Universal2D ||
      //      _pipeline == Pipeline.UniversalForward )
      Task($"Validate pipeline: {pipelineName}");
      if ( _initTasks )
        _tasks.Add(ValidatePipeline);

      // Layers
      if ( _configLayers )
      {
        Task("Config sorting layers");
        if ( _initTasks )
          _tasks.Add(ConfigLayers);
      }

      // Packages
      if ( _configPackageShapes )
      {
        Task("Install 2D Sprite Shapes package");
        if ( _initTasks )
          _tasks.Add(InstallDependencies);
      }

      // Player
      Task("Config Player: Linear color space");
      if ( _initTasks )
        _tasks.Add(ConfigPlayer);

      // Editor
      Task("Config Editor: 2D workflow mode");
      if ( _initTasks )
        _tasks.Add(ConfigEditor);

      if ( _initTasks )
      {
        _initTasks = false;
        _continue = false;
        _isProgress = true;
        NextTask();
      }

      if ( !_nextTask )
        return;
      _nextTask = false;

      if ( _currentTask == _tasks.Count )
      {
        CompleteInstallation();
        _continue = true;
        _isProgress = false;
        _disableForceInstall = true;
        return;
      }

      Action task = _tasks[_currentTask];
      task();
    }

    private void StepEnjoy ()
    {
      Rect rect = CONTENT_RECT;
      rect.width /= 2;
      rect.x += rect.width / 2;
      rect.y += PADDING;
      rect.height = 64;

      if ( GUI.Button(rect, "Online Manual & Support", STYLE_ENJOY_BUTTON) )
        Application.OpenURL(_manualLink);

      rect.y += rect.height + 2 * PADDING;
      rect.height = 160;
      float addition = rect.width / 2;
      rect.x -= addition / 2;
      rect.width += addition;

      const string text =
        "<b>We strive to provide you with the highest - quality assets possible;</b> " +
        "if you find something missing, unclear, or have a suggestion, please contact us – we are here to assist, help, and support!" +
        "\n\n<i>Offline manual is also available. Look for the READ ME file inside the 2D Hand Painted folder.</i>";
      GUI.Label(rect, text, STYLE_RICH);
    }

    private static Pipeline DetectPipeline ()
    {
      _urpAssetsCount = 0;
      RenderPipelineAsset pipelineAsset = GraphicsSettings.renderPipelineAsset;
      if ( pipelineAsset == null )
        return Pipeline.BuiltIn;

      Type pipelineAssetType = pipelineAsset.GetType();
      string typeName = pipelineAssetType.Name;
      if ( typeName.Contains("HDRenderPipelineAsset") )
        return Pipeline.Hd;

      if ( !typeName.Contains("UniversalRenderPipelineAsset") )
        return Pipeline.Unrecognized;

      PropertyInfo prop = pipelineAssetType.GetProperty("scriptableRenderer");
      if ( prop == null )
        return Pipeline.Unrecognized;

      _urpAssetsCount = AssetDatabase
                        .FindAssets("t:UniversalRenderPipelineAsset")
                        .Length;
      string rendererName = prop.GetValue(pipelineAsset).GetType().Name;
      return rendererName.Contains("Renderer2D")
        ? Pipeline.Universal2D
        : Pipeline.UniversalForward;
    }

    private void ValidatePipeline ()
    {
      string[] guids = AssetDatabase.FindAssets("t:Renderer2DData");
      foreach ( string guid in guids )
      {
        string path = AssetDatabase.GUIDToAssetPath(guid);
        Object renderer = AssetDatabase.LoadMainAssetAtPath(path);
        SerializedObject serialized = new SerializedObject(renderer);
        SerializedProperty prop =
          serialized.FindProperty("m_TransparencySortMode");
        prop.intValue = 2; // Orthographic
        serialized.ApplyModifiedProperties();
      }

      AssetDatabase.SaveAssets();
      NextTask();
    }

    private void ConfigPlayer ()
    {
      PlayerSettings.colorSpace = ColorSpace.Linear;
      NextTask();
    }

    private void ConfigEditor ()
    {
      EditorSettings.defaultBehaviorMode = EditorBehaviorMode.Mode2D;
      NextTask();
    }

    private void ConfigLayers ()
    {
      if ( _bundleMeta.TagsLayersVersion >= TAGS_LAYERS_VERSION )
      {
        NextTask();
        return;
      }

      Object assetTags =
        AssetDatabase.LoadMainAssetAtPath("ProjectSettings/TagManager.asset");
      if ( assetTags == null )
      {
        NextTask();
        return;
      }

      Preset assetSource = AssetDatabase.LoadAssetAtPath<Preset>(TAGS_PRESET);
      if ( assetSource == null )
      {
        NextTask();
        return;
      }

      assetSource.ApplyTo(assetTags);
      _bundleMeta.TagsLayersVersion = TAGS_LAYERS_VERSION;
      AssetDatabase.SaveAssets();

      NextTask();
    }

    private void InstallDependencies ()
    {
      const string packAddress = "com.unity.2d.spriteshape";
      AddRequest request = Client.Add(packAddress);
      EditorApplication.update += WaitForInstallation;

      void WaitForInstallation ()
      {
        if ( request.Status == StatusCode.InProgress )
          return;

        EditorApplication.update -= WaitForInstallation;
        NextTask();
      }
    }

    private void NextTask ()
    {
      _nextTask = true;
      _currentTask++;
      Repaint();
    }

    private void CompleteInstallation ()
    {
      _titleCache = _title;
      _manualLink = _pendingPacks.Count == 1
        ? _pendingPacks[0].Manual
        : "https://notslot.com/assets/2d-hand-painted/manual";

      foreach ( PackMeta pack in _pendingPacks )
      {
        _bundleMeta.SetVersion(pack.Name, INSTALLER_VERSION);
        EditorUtility.SetDirty(_bundleMeta);

#if !HANDPAINTED2D_SANDBOX
        string path = AssetDatabase.GetAssetPath(pack);
        AssetDatabase.DeleteAsset(path);
        
        AssetDatabase.DeleteAsset(TEMP_MENU_SCRIPT);
#endif
      }

      AssetDatabase.SaveAssets();
    }

    private static void SkipInstallation (BundleMeta bundleMeta,
                                          IEnumerable<string> guids)
    {
      foreach ( string guid in guids )
      {
        string path = AssetDatabase.GUIDToAssetPath(guid);
        PackMeta pack = AssetDatabase.LoadAssetAtPath<PackMeta>(path);
        bundleMeta.SetVersion(pack.Name, INSTALLER_VERSION);
        EditorUtility.SetDirty(bundleMeta);

#if !HANDPAINTED2D_SANDBOX
        AssetDatabase.DeleteAsset(path);
        AssetDatabase.DeleteAsset(TEMP_MENU_SCRIPT);
#endif
      }

      AssetDatabase.SaveAssets();
    }

    public static void AddDefineSymbol (string symbol)
    {
      BuildTargetGroup targetGroup =
        EditorUserBuildSettings.selectedBuildTargetGroup;
      string symbols =
        PlayerSettings.GetScriptingDefineSymbolsForGroup(targetGroup);
      if ( symbols.Contains(symbol) )
        return;

      // First symbol
      if ( string.IsNullOrEmpty(symbols) )
      {
        PlayerSettings.SetScriptingDefineSymbolsForGroup(targetGroup, symbol);
        return;
      }

      // Has existing symbols
      if ( !symbols[symbols.Length - 1].Equals(';') )
        symbols += ';';

      symbols += symbol;
      PlayerSettings.SetScriptingDefineSymbolsForGroup(targetGroup, symbols);
    }

    #endregion
  }
}